import time
import term
import smq

fn main() {
	client := smq.SmqClient.new(addr: '127.0.0.1', port: 6789)
	start := time.now()
	resp := client.count('default')!
	num :=  resp.data?.int()
	for _ in 0 .. num {
		client.get('default')!
	}
	duration := time.since(start)
	println(term.green('spent ${duration} to get ${num} data into queue'))
}
