import time
import rand
import term
import smq

fn main() {
	client := smq.SmqClient.new(addr: '127.0.0.1', port: 6789)
	start := time.now()
	num := 10000
	for _ in 0 .. num {
		random_str := rand.string(50)
		client.put('default', random_str)!
	}
	duration := time.since(start)
	println(term.green('spent ${duration} to put ${num} data into queue'))
}
