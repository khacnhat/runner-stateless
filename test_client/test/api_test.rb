require_relative 'test_base'

class ApiTest < TestBase

  def self.hex_prefix
    '375'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # start-files image_name<->os correctness
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  multi_os_test '8A1',
  'os-image correspondence' do
    etc_issue = assert_cyber_dojo_sh('cat /etc/issue')
    diagnostic = [
      "image_name=:#{image_name}:",
      "did not find #{os} in etc/issue",
      etc_issue
    ].join("\n")
    case os
    when :Alpine
      assert etc_issue.include?('Alpine'), diagnostic
    when :Ubuntu
      assert etc_issue.include?('Ubuntu'), diagnostic
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # robustness
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  multi_os_test '2F0',
  'call to non existent method becomes exception' do
    assert_exception('does_not_exist', {}.to_json)
  end

  # - - - - - - - - - - - - - - - - - - -

  multi_os_test '2F1',
  'call to existing method with bad json becomes exception' do
    assert_exception('does_not_exist', '{x}')
  end

  # - - - - - - - - - - - - - - - - - - -

  multi_os_test '2F2',
  'call to existing method with missing argument becomes exception' do
    args = { image_name:image_name, id:id }
    assert_exception('kata_new', args.to_json)
  end

  # - - - - - - - - - - - - - - - - - - -

  multi_os_test '2F3',
  'call to existing method with bad argument type becomes exception' do
    args = {
      image_name:image_name,
      id:id,
      files:2, # <=====
      max_seconds:2
    }
    assert_exception('run_cyber_dojo_sh', args.to_json)
  end

  include HttpJsonService

  def hostname
    'runner-stateless'
  end

  def port
    4597
  end

  def assert_exception(method_name, jsoned_args)
    json = http(method_name, jsoned_args) { |uri|
      Net::HTTP::Post.new(uri)
    }
    refute_nil json['exception']
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # invalid arguments
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  METHOD_NAMES = [ :run_cyber_dojo_sh ]

  MALFORMED_IMAGE_NAMES = [ nil, '_cantStartWithSeparator' ]

  multi_os_test 'D21',
  'all api methods raise when image_name is invalid' do
    METHOD_NAMES.each do |method_name|
      MALFORMED_IMAGE_NAMES.each do |image_name|
        error = assert_raises(ServiceError, method_name.to_s) do
          self.send method_name, { image_name:image_name }
        end
        json = JSON.parse(error.message)
        assert_equal 'RunnerStatelessService', json['class']
        assert_equal 'image_name:malformed', json['message']
        assert_equal 'Array', json['backtrace'].class.name
      end
    end
  end

  MALFORMED_IDS = [ nil, '675' ]

  multi_os_test '656',
  'all api methods raise when kata_id is invalid' do
    METHOD_NAMES.each do |method_name|
      MALFORMED_IDS.each do |id|
        error = assert_raises(ServiceError, method_name.to_s) do
          self.send method_name, { id:id }
        end
        json = JSON.parse(error.message)
        assert_equal 'RunnerStatelessService', json['class']
        assert_equal 'id:malformed', json['message']
        assert_equal 'Array', json['backtrace'].class.name
      end
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # red-amber-green
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '3DF',
  '[C,assert] run with initial 6*9 == 42 is red' do
    run_cyber_dojo_sh
    assert red?, result

    run_cyber_dojo_sh({
      changed_files: {
        'hiker.c' => file(hiker_c.sub('6 * 9', '6 * 9sd'))
      }
    })
    assert amber?, result

    run_cyber_dojo_sh({
      changed_files: {
        'hiker.c' => file(hiker_c.sub('6 * 9', '6 * 7'))
      }
    })
    assert green?, result
  end

  def hiker_c
    starting_files['hiker.c']['content']
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # timing out
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '3DC',
  '[C,assert] run with infinite loop times out' do
    from = 'return 6 * 9'
    to = "    for (;;);\n    return 6 * 7;"
    run_cyber_dojo_sh({
      changed_files: { 'hiker.c' => file(hiker_c.sub(from, to)) },
        max_seconds: 3
    })
    assert timed_out?, result
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # large-files
  # docker-compose.yml need a tmpfs for this to pass
  #      tmpfs: /tmp
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  multi_os_test '3DB',
  'run with very large file is red' do
    run_cyber_dojo_sh({
      created_files: { 'big_file' => file('X'*1023*500) }
    })
    assert red?, result
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  multi_os_test 'ED4',
  'stdout greater than 25K is truncated' do
    # [1] fold limit is 10000 so I do five smaller folds
    five_K_plus_1 = 5*1024+1
    command = [
      'cat /dev/urandom',
      "tr -dc 'a-zA-Z0-9'",
      "fold -w #{five_K_plus_1}", # [1]
      'head -n 1'
    ].join('|')
    run_cyber_dojo_sh({
      changed_files: {
        'cyber-dojo.sh' => file("seq 5 | xargs -I{} sh -c '#{command}'")
      }
    })
    assert result['stdout']['truncated']
  end

end
