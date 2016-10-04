# == Class: sentry::service
#
# This class is meant to be called from sentry.
# It ensures the service is running.
#
class sentry::service
{
  $command = join([
    "${sentry::path}/virtualenv/bin/sentry",
    "--config=${sentry::path}"
  ], ' ')

  Supervisord::Program {
    ensure          => present,
    directory       => $sentry::path,
    user            => $sentry::owner,
    autostart       => true,
    redirect_stderr => true,
  }

  anchor { 'sentry::service::begin': } ->

  supervisord::program {
    'sentry-cron':
      command => "${command} start cron",
    ;
    'sentry-http':
      command => "${command} start http",
    ;
    'sentry-worker':
      command => "${command} run worker",
    ;
  } ->

  anchor { 'sentry::service::end': }

  if $sentry::service_restart {
    Anchor['sentry::service::begin'] ~>

    supervisord::supervisorctl { 'sentry_reload':
      command     => 'reload',
      refreshonly => true,
    }
  }
}
