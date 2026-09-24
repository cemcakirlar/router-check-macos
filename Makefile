.PHONY: build app run clean

build:
	swift build

app:
	./scripts/build_app.sh

run: app
	open build/RouterCheck.app

clean:
	rm -rf .build build
