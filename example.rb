require 'everlastly'

Everlastly.setup do | config |
    config.public_key = 'pub key'
    config.private_key = 'priv key'
end

example_hash="3e79ffa0e95c435ec8ee50ebb6959259968b4c66852d4fba4fc0876e83b4a0e1"

anchor_result = Everlastly.anchor example_hash, metadata: {"additional info":"隨機詞"}

p Everlastly.get_receipts([ anchor_result[:receiptID], ]) if anchor_result[:success]
 
