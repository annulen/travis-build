require 'spec_helper'

describe Travis::Build::Script::Go do
  let(:options) { { logs: { build: false, state: false } } }
  let(:data)    { PAYLOADS[:push].deep_clone }

  subject { described_class.new(data, options).compile }

  after :all do
    store_example
  end

  it_behaves_like 'a build script'

  it 'sets GOPATH' do
    should set 'GOPATH', %r@[^:]*#{Travis::Build::HOME_DIR}/gopath:.*@
  end

  it 'sets TRAVIS_GO_VERSION' do
    should set 'TRAVIS_GO_VERSION', 'go1.0.3'
  end

  it 'sets the default go version if not :gvm config given' do
    should setup 'gvm use go1.0.3'
  end

  it 'sets the go version from config :gvm' do
    data['config']['gvm'] = 'go1.1'
    should setup 'gvm use go1.1'
  end

  it 'creates the src dir' do
    should run "mkdir -p #{Travis::Build::HOME_DIR}/gopath/src/github.com/travis-ci"
  end

  it "copies the repository to the GOPATH" do
    should run "cp -r #{Travis::Build::BUILD_DIR}/travis-ci/travis-ci #{Travis::Build::HOME_DIR}/gopath/src/github.com/travis-ci/travis-ci"
  end

  it "updates TRAVIS_BUILD_DIR" do
    should set "TRAVIS_BUILD_DIR", "#{Travis::Build::HOME_DIR}/gopath/src/github.com/travis-ci/travis-ci"
  end

  it "cds to the GOPATH version of the project" do
    should run "cd #{Travis::Build::HOME_DIR}/gopath/src/github.com/travis-ci/travis-ci"
  end

  it 'installs the gvm version' do
    data['config']['gvm'] = 'go1.1'
    should run 'gvm install go1.1'
  end

  it 'announces go version' do
    should announce 'go version'
  end

  it 'announces gvm version' do
    should announce 'gvm version'
  end

  it 'announces go env' do
    should announce 'go env'
  end

  it 'folds go env' do
    should fold 'go env', 'go.env'
  end

  it 'folds gvm install' do
    should fold 'gvm install', 'gvm.install'
  end

  describe 'if no makefile exists' do
    it 'installs with go get and go build' do
      should run 'echo $ go get -d -v ./... && go build -v ./...'
      should run 'go get -d -v ./...', retry: true
      should run 'go build -v ./...', log: true, assert: true, timeout: timeout_for(:install)
    end

    it 'runs go test' do
      should run_script 'go test -v ./...'
    end
  end

  %w(GNUmakefile makefile Makefile BSDmakefile).each do |makefile_name|
    describe "if #{makefile_name} exists" do
      before(:each) do
        file(makefile_name)
      end

      it 'does not install with go get' do
        should_not run 'go get'
      end

      it 'runs make' do
        should run_script 'make'
      end
    end
  end
end
