require_relative '../../src/rack_dispatcher'
#require_relative 'bash_stub_status'
require_relative 'malformed_data'
require_relative 'rack_request_stub'
require_relative 'test_base'
require 'json'

class RackDispatcherTest < TestBase

  def self.hex_prefix
    'D06F7'
  end

  # - - - - - - - - - - - - - - - - -

  test 'BAF',
  %w( unknown method becomes exception ) do
    expected = 'json:malformed'
    assert_rack_call_exception(expected, nil,       '{}')
    assert_rack_call_exception(expected, [],        '{}')
    assert_rack_call_exception(expected, {},        '{}')
    assert_rack_call_exception(expected, true,      '{}')
    assert_rack_call_exception(expected, 42,        '{}')
    assert_rack_call_exception(expected, 'unknown', '{}')
  end

  # - - - - - - - - - - - - - - - - -

  test 'BB0',
  %w( malformed json in http payload becomes exception ) do
    expected = 'json:malformed'
    METHOD_NAMES.each do |method_name|
      assert_rack_call_exception(expected, method_name, 'sdfsdf')
      assert_rack_call_exception(expected, method_name, 'nil')
      assert_rack_call_exception(expected, method_name, 'null')
      assert_rack_call_exception(expected, method_name, '[]')
      assert_rack_call_exception(expected, method_name, 'true')
      assert_rack_call_exception(expected, method_name, '42')
    end
  end

  # - - - - - - - - - - - - - - - - -

  test 'BB2',
  %w( malformed image_name becomes exception ) do
    malformed_image_names.each do |malformed|
      assert_rack_call_exception('image_name:malformed', 'kata_new', {
        image_name:malformed,
        kata_id:kata_id
      }.to_json)
    end
  end

  # - - - - - - - - - - - - - - - - -

  test 'BB3',
  %w( malformed kata_id becomes exception ) do
    malformed_kata_ids.each do |malformed|
      assert_rack_call_exception('kata_id:malformed', 'kata_new', {
        image_name:image_name,
        kata_id:malformed
      }.to_json)
    end
  end

  # - - - - - - - - - - - - - - - - -

  test 'BB4',
  %w( malformed starting_files becomes exception ) do
    malformed_files.each do |malformed|
      assert_rack_call_exception('starting_files:malformed', 'avatar_new', {
        image_name:image_name,
        kata_id:kata_id,
        avatar_name:'salmon',
        starting_files:malformed
      }.to_json)
    end
  end

  # - - - - - - - - - - - - - - - - -

  test 'BB5',
  %w( malformed avatar_name becomes exception ) do
    malformed_avatar_names.each do |malformed|
      assert_rack_call_exception('avatar_name:malformed', 'avatar_old', {
        image_name:image_name,
        kata_id:kata_id,
        avatar_name:malformed
      }.to_json)
    end
  end

  # - - - - - - - - - - - - - - - - -

  test 'BB7',
  %w( malformed max_seconds becomes exception ) do
    malformed_max_seconds.each do |malformed|
      assert_rack_call_run_malformed({max_seconds:malformed})
    end
  end

  # - - - - - - - - - - - - - - - - -

  test 'BB8',
  %w( malformed files becomes exception ) do
    malformed_files.each do |malformed|
      assert_rack_call_run_malformed({new_files:malformed})
      assert_rack_call_run_malformed({deleted_files:malformed})
      assert_rack_call_run_malformed({unchanged_files:malformed})
      assert_rack_call_run_malformed({changed_files:malformed})
    end
  end

  # - - - - - - - - - - - - - - - - -
  # sha
  # - - - - - - - - - - - - - - - - -

  test 'AB0', 'sha' do
    path_info = 'sha'
    env = { body:{}.to_json, path_info:path_info }
    rack_call(env)
    assert_200
    assert_sha(JSON.parse(@body)[path_info])
    refute_body_contains('exception')
    refute_body_contains('trace')
    assert_nothing_logged
  end

  def assert_sha(string)
    assert_equal 40, string.size
    string.each_char do |ch|
      assert '0123456789abcdef'.include?(ch)
    end
  end

  # - - - - - - - - - - - - - - - - -
  # kata_new
  # - - - - - - - - - - - - - - - - -

  test 'AB1', 'kata_new' do
    path_info = 'kata_new'
    env = {
      path_info:path_info,
      body: {
        image_name:image_name,
        kata_id:kata_id
      }.to_json
    }
    rack_call(env)
    assert_200
    assert_body_contains(path_info)
    refute_body_contains('exception')
    refute_body_contains('trace')
    assert_nothing_logged
  end

  # - - - - - - - - - - - - - - - - -
  # kata_old
  # - - - - - - - - - - - - - - - - -

  test 'AB2', 'kata_old' do
    path_info = 'kata_old'
    env = {
      path_info:path_info,
      body: {
        image_name:image_name,
        kata_id:kata_id
      }.to_json
    }
    rack_call(env)
    assert_200
    assert_body_contains(path_info)
    refute_body_contains('exception')
    refute_body_contains('trace')
    assert_nothing_logged
  end

  # - - - - - - - - - - - - - - - - -
  # avatar_new
  # - - - - - - - - - - - - - - - - -

  test 'AB3', 'avatar_new' do
    path_info = 'avatar_new'
    env = {
      path_info:path_info,
      body: {
        image_name:image_name,
        kata_id:kata_id,
        avatar_name:'salmon',
        starting_files:{}
      }.to_json
    }
    rack_call(env)
    assert_200
    assert_body_contains(path_info)
    refute_body_contains('exception')
    refute_body_contains('trace')
    assert_nothing_logged
  end

  # - - - - - - - - - - - - - - - - -
  # avatar_old
  # - - - - - - - - - - - - - - - - -

  test 'AB4', 'avatar_old' do
    path_info = 'avatar_old'
    env = {
      path_info:path_info,
      body: {
        image_name:image_name,
        kata_id:kata_id,
        avatar_name:'salmon'
      }.to_json
    }
    rack_call(env)
    assert_200
    assert_body_contains(path_info)
    refute_body_contains('exception')
    refute_body_contains('trace')
    assert_nothing_logged
  end

  # - - - - - - - - - - - - - - - - -
  # run_cyber_dojo_sh
  # - - - - - - - - - - - - - - - - -

  test 'AB5', '[C,assert] run_cyber_dojo_sh' do
    path_info = 'run_cyber_dojo_sh'
    args = {
      image_name:image_name,
      kata_id:kata_id,
      avatar_name:'salmon',
      new_files:starting_files,
      deleted_files:{},
      unchanged_files:{},
      changed_files:{},
      max_seconds:10
    }
    env = { path_info:path_info, body:args.to_json }
    rack_call(env)
    assert_200
    assert_body_contains(path_info)
    refute_body_contains('exception')
    refute_body_contains('trace')
    assert_nothing_logged

    # Careful here...
    # stderr may or may not have ' (core dumped)' appended.
    # Note that --ulimit core=0 is in place in the runner so
    # no core file is -actually- dumped.
    result = JSON.parse(@body)[path_info]
    # C,assert output is compiler-OS dependent. This is gcc,Debian
    assert_equal gcc_assert_stdout, result['stdout']
    assert result['stderr'].start_with?(gcc_assert_stderr), result['stderr']
    assert_equal 2, result['status']
    assert_equal 'red', result['colour']
  end

  # - - - - - - - - - - - - - - - - -

=begin
  test 'AB6', 'example of run_cyber_dojo_sh with some logging' do
    path_info = 'run_cyber_dojo_sh'
    args = {
      image_name:image_name,
      kata_id:kata_id,
      avatar_name:'salmon',
      new_files:starting_files,
      deleted_files:{},
      unchanged_files:{},
      changed_files:{},
      max_seconds:10
    }
    env = { path_info:path_info, body:args.to_json }

    rack = RackDispatcher.new(cache)
    stub = BashStubStatus.new(4)
    external = External.new({ 'bash' => stub })

    code,json = nil,nil
    written = with_captured_stdout {
      triple = rack.call(env, external, RackRequestStub)
      code = triple[0]
      type = triple[1]
      json = JSON.parse(triple[2][0])
      expected_type = { 'Content-Type' => 'application/json' }
      assert_equal expected_type, type
    }

    #TODO: written is the same as json

    assert stub.fired?
    assert_500 code
    #assert_empty_log(json)     # summat is logged
    #assert_no_exception(json)  # there is an exception
    #assert_no_trace(json)      # there is a trace

    assert_equal ['exception','log','trace'], json.keys.sort
    refute_nil json['exception']
    refute_nil json['log']
    refute_nil json['trace']

    # TODO: too much content in exception
    #       failed shell command is in log anyway...
    #       I think the exception should contains its own json data
    #
    #puts "exception:#{json['exception']}\n\n"

    #puts "log:#{json['log']}\n\n"

    #puts "trace:#{json['trace']}\n\n"

  end

  def assert_500(code)
    assert_equal 500,code
  end

=end

  private # = = = = = = = = = = = = =

  include MalformedData

  # - - - - - - - - - - - - - - - - -

  def assert_rack_call_run_malformed(added)
    expected = "#{added.keys[0]}:malformed"
    assert_rack_call_exception(expected, 'run_cyber_dojo_sh', {
      image_name:image_name,
      kata_id:kata_id,
      avatar_name:'salmon',
      new_files:{},
      deleted_files:{},
      unchanged_files:{},
      changed_files:{ 'cyber-dojo.sh' => 'pwd' },
      max_seconds:10
    }.merge(added).to_json)
  end

  # - - - - - - - - - - - - - - - - -

  def assert_rack_call_exception(expected, path_info, body)
    env = { path_info:path_info, body:body }
    rack_call(env)
    assert_400
    assert_body_contains('exception', expected)
    assert_body_contains('trace')
    assert_log_contains('exception', expected)
    assert_log_contains('trace')
  end

  # - - - - - - - - - - - - - - - - -

  def rack_call(env)
    rack = RackDispatcher.new(cache)
    with_captured_log {
      triple = rack.call(env, external, RackRequestStub)
      @code = triple[0]
      @type = triple[1]
      @body = triple[2][0]
    }
    expected_type = { 'Content-Type' => 'application/json' }
    assert_equal expected_type, @type
  end

  # - - - - - - - - - - - - - - - - -

  def assert_200
    assert_equal 200, @code
  end

  def assert_400
    assert_equal 400, @code
  end

  # - - - - - - - - - - - - - - - - -

  def assert_body_contains(key, value = nil)
    refute_nil @body
    json = JSON.parse(@body)
    assert json.has_key?(key)
    unless value.nil?
      assert_equal value, json[key]
    end
  end

  def refute_body_contains(key)
    refute_nil @body
    json = JSON.parse(@body)
    refute json.has_key?(key)
  end

  # - - - - - - - - - - - - - - - - -

  def assert_log_contains(key, value = nil)
    refute_nil @log
    json = JSON.parse(@log)
    assert json.has_key?(key)
    unless value.nil?
      assert_equal value, json[key]
    end
  end

  def assert_nothing_logged
    assert_equal '', @log
  end

  # - - - - - - - - - - - - - - - - -

  def gcc_assert_stdout
    # gcc,Debian
    "makefile:14: recipe for target 'test.output' failed\n"
  end

  def gcc_assert_stderr
    # This depends partly on the host-OS. For example, when
    # the host-OS is CoreLinux (in the boot2docker VM
    # in DockerToolbox for Mac) then the output ends
    # ...Aborted (core dumped).
    # But if the host-OS is Debian/Ubuntu (eg on Travis)
    # then the output does not say "(core dumped)"
    "test: hiker.tests.c:7: life_the_universe_and_everything: Assertion `answer() == 42' failed.\n" +
    "make: *** [test.output] Aborted"
  end

  # - - - - - - - - - - - - - - - - -

  METHOD_NAMES = %w(
    sha
    kata_new kata_old
    avatar_new avatar_old
    run_cyber_dojo_sh
  )

end
