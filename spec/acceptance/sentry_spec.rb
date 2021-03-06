require 'spec_helper_acceptance'

describe 'sentry' do
  context 'with default parameters' do
    let(:pp) {"
      class { 'sentry':
      }
    "}

    it 'applies with no errors' do
      apply_manifest(pp, :catch_failures => true)
    end

    it 'is idempotent' do
      apply_manifest(pp, :catch_changes => true)
    end

    describe service('supervisord') do
      it { is_expected.to be_enabled }
      it { is_expected.to be_running }
    end

    describe command('supervisorctl status sentry-http') do
      its(:stdout) { is_expected.to match(/RUNNING/) }
      its(:stderr) { is_expected.to be_empty }
      its(:exit_status) { is_expected.to eq 0 }
    end

    describe port(9000) do
      it {
        sleep 10  # wait for daemon to fully start
        is_expected.to be_listening
      }
    end

    describe command('supervisorctl status sentry-worker') do
      its(:stdout) { is_expected.to match(/RUNNING/) }
      its(:stderr) { is_expected.to be_empty }
      its(:exit_status) { is_expected.to eq 0 }
    end

    describe command("#{SENTRY_COMMAND} dumpdata sentry.user") do
      its(:stderr) { is_expected.to match(/"pk": 2/) }
      its(:stderr) { is_expected.to match(/"password": "pbkdf2_sha256\$[[:digit:]]{5,}\$[[:ascii:]]{12,}\$[[:ascii:]]{43}="/) }
      its(:stderr) { is_expected.to match(/"email": "admin@localhost"/) }
      its(:stderr) { is_expected.to match(/"username": "admin@localhost"/) }
      its(:exit_status) { is_expected.to eq 0 }
    end
  end
end
