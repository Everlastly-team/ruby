require 'everlastly'

Everlastly.setup do | config |
    config.public_key = 'pub_key'
    config.private_key = 'priv_key'
end

anchor_tests = [
 { arguments: {hash: '1'*64, kwargs: {} }, success: true, error: nil},
 { arguments: {hash: '1'*64, kwargs: {metadata: { 隨機詞: '👌'}} }, success: true, error: nil},
 { arguments: {hash: '1'*64, kwargs: {metadata: { 隨機詞: '👌'}, save_dochash_in_receipt: true} }, success: true, error: nil},
 { arguments: {hash: '1'*64, kwargs: {metadata: { 隨機詞: '👌'}, save_dochash_in_receipt: true, no_salt: true} }, success: true, error: nil},
 { arguments: {hash: '1'*64, kwargs: {metadata: { 隨機詞: '👌'}, save_dochash_in_receipt: true, no_salt: true, no_nonce: true} }, success: true, error: nil},
 { arguments: {hash: '1'*63, kwargs: {} }, success: false, error: "Wrong length of `hash` parameter\n"},
]

def run_anchor_tests (tests)
  raise_on_errors = true
  print_positive = true
  uuids = []
  tests.each_with_index do | test, index |
    begin
      dochash = test[:arguments][:hash]
      params = test[:arguments][:kwargs]
      success = test[:success]
      error = test[:error]
    rescue Exception => msg  
      puts msg
      raise ArgumentError, "Bad formed test #{test}"
    end
    res = Everlastly.anchor dochash, params
    unless res[:success]==success
      msg = "For test \n#{test} we got \n#{res}"
      if raise_on_errors then raise(ArgumentError, msg) else  puts(msg)  end
    else
      if (not res[:success]) and (error!=res[:error_message])
        raise ArgumentError, "For test \n#{test} we got error `#{res[:error_message]}`, but expected `#{error}`"
      elsif print_positive
        puts "👌OK\tAnchor test #{index} done correctly"
      end
    end
    uuids.push res[:receiptID] if res[:success]
  end
  uuids
end


def run_get_receipts_tests (receipt_list)
  raise_on_errors = true
  print_positive = true
  receipt_list = ['Not token', 'eb6c398d-341c-4d3b-81f0-225958991a5f'] + receipt_list
  res = Everlastly.get_receipts receipt_list 
  preliminary_success = true
  raise RuntimeError, 'Bad response from server' unless res[:success]
  bad_receipts, good_receipts = res[:receipts][0...2], res[:receipts][2..-1]
  bad_receipts.each_with_index do | br, index |
    unless br["status"]=="Error"
      msg = "Problem with #{index} example: #{br}"
      preliminary_success = false
      if raise_on_errors then raise(ArgumentError, msg) else puts(msg) end
    end
  end
  good_receipts.each_with_index do | gr, index |
    unless gr["status"]=="Success"
      msg = "Problem with #{index} example: #{gr}"
      preliminary_success = false
      if raise_on_errors then raise(ArgumentError, msg) else puts(msg) end
    end
  end
  puts "👌OK\tGet_receipts test 0 done correctly" if print_positive
end



uuids = run_anchor_tests anchor_tests
sleep(0.2) # Give server time to put tests to db
run_get_receipts_tests uuids
