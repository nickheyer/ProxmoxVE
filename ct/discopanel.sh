#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/nickheyer/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: nickheyer
# License: MIT | https://github.com/nickheyer/ProxmoxVE/raw/main/LICENSE
# Source: https://discopanel.app/

APP="DiscoPanel"
var_tags="${var_tags:-gaming}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-15}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d "/opt/discopanel" ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if ! setup_docker; then
    msg_error "Docker failed"
    exit 1
  fi

  if check_for_gh_release "discopanel" "nickheyer/discopanel"; then
    msg_info "Stopping Service"
    systemctl stop discopanel
    msg_ok "Stopped Service"

    msg_info "Creating Backup"
    mkdir -p /opt/discopanel_backup_temp
    cp -r /opt/discopanel/data/* /opt/discopanel_backup_temp/.
    msg_ok "Created Backup"

    msg_info "Setting up DiscoPanel"
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "discopanel" "nickheyer/discopanel" "prebuild" "latest" "/opt/discopanel" "discopanel-linux-amd64.tar.gz"
    msg_info "Setup DiscoPanel"

    msg_info "Restoring Data"
    mkdir -p /opt/discopanel/data
    cp -a /opt/discopanel_backup_temp/. /opt/discopanel/data/
    rm -rf /opt/discopanel_backup_temp
    msg_ok "Restored Data"

    msg_info "Starting Service"
    systemctl start discopanel
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
