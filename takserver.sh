#!/usr/bin/bash

# Here is a script to deploy an certs on TAK Server.


#returns 0 means success, otherwise error.

# The default server certificate file location (.jks file), certificate
# alias, keystore password, and command to restart the TAK Server are
# shown below.  If you want to use different values, you should set the
# appropriate variable before running this script for the first time.
# custom values will be saved and used thereafter when the script is run.
#
# Settings for TAK Server:
# Location of Java keystore .jks file:
#DEPLOY_TAKSERVER_KEYSTORE="/opt/tak/certs/files/acme-<domain-name>.jks"
# Certificate alias
#DEPLOY_TAKSERVER_CERT_ALIAS="takserver"
# Keystore password:
#DEPLOY_TAKSERVER_KEYPASS="atakatak"
# Command to restart TAK Server:
#DEPLOY_TAKSERVER_RELOAD="chown -R tak /opt/tak/ && systemctl restart takserver"
#

########  Public functions #####################

#domain keyfile certfile cafile fullchain
takserver_deploy() {
  _cdomain="$1"
  _ckey="$2"
  _ccert="$3"
  _cca="$4"
  _cfullchain="$5"

  _debug _cdomain "$_cdomain"
  _debug _ckey "$_ckey"
  _debug _ccert "$_ccert"
  _debug _cca "$_cca"
  _debug _cfullchain "$_cfullchain"

  _getdeployconf DEPLOY_TAKSERVER_KEYSTORE
  _getdeployconf DEPLOY_TAKSERVER_CERT_ALIAS
  _getdeployconf DEPLOY_TAKSERVER_KEYPASS
  _getdeployconf DEPLOY_TAKSERVER_RELOAD

  _debug2 DEPLOY_TAKSERVER_KEYSTORE "$DEPLOY_TAKSERVER_KEYSTORE"
  _debug2 DEPLOY_TAKSERVER_KEYPASS "$DEPLOY_TAKSERVER_KEYPASS"
  _debug2 DEPLOY_TAKSERVER_CERT_ALIAS "$DEPLOY_TAKSERVER_CERT_ALIAS"
  _debug2 DEPLOY_TAKSERVER_RELOAD "$DEPLOY_TAKSERVER_RELOAD"

  # Space-separated list of environments detected and installed:
  _services_updated=""

  # Default reload commands accumulated as we auto-detect environments:
  _reload_cmd=""

  _takserver_keystore="${DEPLOY_TAKSERVER_KEYSTORE:-/opt/tak/certs/files/acme-$_cdomain.jks}"
  if [ -f "$_takserver_keystore" ]; then
    _info "Installing certificate for TAK Server (Java keystore)"
    _debug _takserver_keystore "$_takserver_keystore"
    if ! _exists keytool; then
      _err "keytool not found"
      return 1
    fi
    if [ ! -w "$_takserver_keystore" ]; then
      _err "The file $_takserver_keystore is not writable, please change the permission."
      return 1
    fi

    _takserver_keypass="${DEPLOY_TAKSERVER_KEYPASS:-atakatak}"
	_takserver_cert_alias="${DEPLOY_TAKSERVER_CERT_ALIAS:-$_cdomain}"

    _debug "Generate import pkcs12"
    _import_pkcs12="$(_mktemp)"
    _toPkcs "$_import_pkcs12" "$_ckey" "$_ccert" "$_cca" "$_takserver_keypass" "$_takserver_cert_alias" root
    # shellcheck disable=SC2181
    if [ "$?" != "0" ]; then
      _err "Error generating pkcs12. Please re-run with --debug and report a bug."
      return 1
    fi

    _debug "Import into keystore: $_takserver_keystore"
    if keytool -importkeystore \
      -deststorepass "$_takserver_keypass" -destkeypass "$_takserver_keypass" -destkeystore "$_takserver_keystore" \
      -srckeystore "$_import_pkcs12" -srcstoretype PKCS12 -srcstorepass "$_takserver_keypass" \
      -alias "$_takserver_cert_alias" -noprompt; then
      _debug "Import keystore success!"
      rm "$_import_pkcs12"
    else
      _err "Error importing into TAK Server keystore."
      _err "Please re-run with --debug and report a bug."
      rm "$_import_pkcs12"
      return 1
    fi

    if systemctl -q is-active takserver; then
      _reload_cmd="${_reload_cmd:+$_reload_cmd && }service takserver restart"
    fi
    _services_updated="${_services_updated} takserver"
    _info "Install TAKServer certificate success!"
  elif [ "$DEPLOY_TAKSERVER_KEYSTORE" ]; then
    _err "The specified DEPLOY_TAKSERVER_KEYSTORE='$DEPLOY_TAKSERVER_KEYSTORE' is not valid, please check."
    return 1
  fi

  _reload_cmd="${DEPLOY_TAKSERVER_RELOAD:-$_reload_cmd}"
  if [ -z "$_reload_cmd" ]; then
    _err "Certificates were installed for services:${_services_updated},"
    _err "but none appear to be active. Please set DEPLOY_TAKSERVER_RELOAD"
    _err "to a command that will restart the necessary services."
    return 1
  fi
  _info "Reload services (this may take some time): $_reload_cmd"
  if eval "$_reload_cmd"; then
    _info "Reload success!"
  else
    _err "Reload error"
    return 1
  fi

  # Successful, so save all (non-default) config:
  _savedeployconf DEPLOY_TAKSERVER_KEYSTORE "$DEPLOY_TAKSERVER_KEYSTORE"
  _savedeployconf DEPLOY_TAKSERVER_KEYPASS "$DEPLOY_TAKSERVER_KEYPASS"
  _savedeployconf DEPLOY_TAKSERVER_CERT_ALIAS "$DEPLOY_TAKSERVER_CERT_ALIAS"
  _savedeployconf DEPLOY_TAKSERVER_RELOAD "$DEPLOY_TAKSERVER_RELOAD"

  return 0
}
