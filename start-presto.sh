#!/bin/bash
PRESTO_ALIAS="my-presto"
PRESTO_TAG="latest"

cdir="`dirname "$0"`"
cdir="`cd "$cdir"; pwd`"

[[ "$TRACE" ]] && set -x

_log() {
  [[ "$2" ]] && echo "[`date +'%Y-%m-%d %H:%M:%S.%N'`] - $1 - $2"
}

info() {
  [[ "$1" ]] && _log "INFO" "$1"
}

warn() {
  [[ "$1" ]] && _log "WARN" "$1"
}

setup_env() {
  info "Load environment variables from $cdir/presto-env.sh..."
  if [ -f $cdir/presto-env.sh ]
  then
    . "$cdir/presto-env.sh"
  else
    warn "Skip presto-env.sh as it does not exist"
  fi

  # check environment variables and set defaults as required
  : ${SERV_PORT:="18283"}
  : ${SERV_URI:="http://localhost:$SERV_PORT"}
  : ${NODE_ENV:="production"}
  : ${NODE_ID:="`python -c 'import uuid; print uuid.uuid1()'`"}
  : ${CONF_DIR:="/data/presto/etc"}
  : ${DATA_DIR:="/data/presto/data"}

  info "Loaded environment variables:"
  info "	NODE_ENV  = $NODE_ENV"
  info "	SERV_URI  = $SERV_URI"
  info "	SERV_PORT = $SERV_PORT"
  info "	CONF_DIR  = $CONF_DIR"
  info "	DATA_DIR  = $DATA_DIR"
}

setup_dir() {
  if [ -d $CONF_DIR ]; then
    info "Reuse existing configuration directory: $CONF_DIR"
  else
    info "Initialize Configuration directory: $CONF_DIR"
    mkdir -p $CONF_DIR
  fi

  if [ ! -f $CONF_DIR/node.properties ]; then
    warn "node.properties not found, generate one with default settings..."
    echo "node.environment=$NODE_ENV" > $CONF_DIR/node.properties
    echo "node.id=$NODE_ID" >> $CONF_DIR/node.properties
    echo "node.data-dir=/presto/data" >> $CONF_DIR/node.properties
    cat $CONF_DIR/node.properties
  else
    sed -ri 's/^(node.environment=).*/\1'"$NODE_ENV"'/' "$CONF_DIR/node.properties"
    sed -ri 's|^(node.data-dir=).*|\1'"/presto/data"'|' "$CONF_DIR/node.properties"
  fi
  
  if [ ! -f $CONF_DIR/jvm.config ]; then
    warn "jvm.config not found, generate one with default settings..."
    echo "-server" > $CONF_DIR/jvm.config
    echo "-Xmx2G" >> $CONF_DIR/jvm.config
    echo "-XX:+UseG1GC" >> $CONF_DIR/jvm.config
    echo "-XX:G1HeapRegionSize=32M" >> $CONF_DIR/jvm.config
    echo "-XX:+UseGCOverheadLimit" >> $CONF_DIR/jvm.config
    echo "-XX:+ExplicitGCInvokesConcurrent" >> $CONF_DIR/jvm.config
    echo "-XX:+HeapDumpOnOutOfMemoryError" >> $CONF_DIR/jvm.config
#    echo "-XX:OnOutOfMemoryError=kill -9 %p" >> $CONF_DIR/jvm.config
    echo "-XX:OnOutOfMemoryError=kill -9 0" >> $CONF_DIR/jvm.config
    cat $CONF_DIR/jvm.config
  fi

  if [ ! -f $CONF_DIR/config.properties ]; then
    warn "config.properties not found, generate one for worker node..."
    echo "coordinator=false" > $CONF_DIR/config.properties
    echo "query.max-memory=4GB" >> $CONF_DIR/config.properties
    echo "query.max-memory-per-node=1GB" >> $CONF_DIR/config.properties
    echo "http-server.http.port=8080" >> $CONF_DIR/config.properties
    echo "discovery.uri=$SERV_URI" >> $CONF_DIR/config.properties
    cat $CONF_DIR/config.properties
  else
    sed -ri 's/^(http-server.http.port=).*/\1'"8080"'/' "$CONF_DIR/config.properties"
    sed -ri 's|^(discovery.uri=).*|\1'"$SERV_URI"'|' "$CONF_DIR/config.properties"
  fi

  if [ ! -f $CONF_DIR/log.properties ]; then
    warn "log.properties not found, generate one with default settings..."
    echo "com.facebook.presto=INFO" > $CONF_DIR/log.properties
    cat $CONF_DIR/log.properties
  fi

  if [ ! -d $CONF_DIR/catalog ]; then
    warn "no catalog found, create one for jmx..."
    mkdir -p $CONF_DIR/catalog
    echo "connector.name=jmx" > $CONF_DIR/catalog/jmx.properties
    cat $CONF_DIR/catalog/jmx.properties
  fi

  if [ -d $DATA_DIR ]; then
    info "Reuse existing data directory: $DATA_DIR"
  else
    info "Initialize data directory: $DATA_DIR"
    mkdir -p $DATA_DIR
  fi
}

start_presto() {
  info "Stop and remove \"$PRESTO_ALIAS\" if it exists and start new one"
  # stop and remove the container if it exists
  docker stop "$PRESTO_ALIAS" >/dev/null 2>&1 && docker rm "$PRESTO_ALIAS" >/dev/null 2>&1

  # use --privileged=true has the potential risk of causing clock drift
  # references: http://stackoverflow.com/questions/24288616/permission-denied-on-accessing-host-directory-in-docker
  docker run -d --name="$PRESTO_ALIAS" --restart=always -h presto -p $SERV_PORT:8080 \
    -v $CONF_DIR:/presto/etc:Z -v $DATA_DIR:/presto/data:Z \
    zhicwu/presto:$PRESTO_TAG

  info "Try 'docker logs -f \"$PRESTO_ALIAS\"' to see if this works"
}

main() {
  setup_env
  setup_dir
  start_presto
}

main "$@"
