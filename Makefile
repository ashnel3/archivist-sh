.PHONY: clean clean-logs clean-tasks test test-sync install uninstall

clean:
	@rm -rf release

clean-tasks:
	@rm -rf tasks/*/

clean-logs:
	@rm -rf tasks/*/*.log

test:
	@rm -rf tasks/test_* releases/test_*
	@bats --tap test
	@rm -rf tasks/test_* releases/test_*

install:
	@./install.sh -y

uninstall:
	@./install.sh -u
