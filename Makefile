# There are only two rules:
# 1. Variables at the top of the Makefile.
# 2. Targets are listed alphabetically. No, really.

WHEREAMI = $(shell pwd)
WHOAMI = $(shell basename $(WHEREAMI))
WHATAMI = $(shell echo $(WHOAMI) | awk -F '-' '{print $$3}')
WHATAMI_REALLY = $(shell basename `pwd` | sed 's/whosonfirst-data-//')

YMD = $(shell date "+%Y%m%d")

# https://github.com/whosonfirst/go-whosonfirst-utils/blob/master/cmd/wof-expand.go
WOF_EXPAND = $(shell which wof-expand)

WOF_BUNDLE_PLACETYPES = $(shell which wof-bundle-placetypes)
WOF_CLONE_METAFILES = $(shell which wof-clone-metafiles)
WOF_BUILD_METAFILES = $(WHEREAMI)/bin/wof-build-metafiles
WOF_BUILD_CONCORDANCES = $(WHEREAMI)/bin/wof-build-concordances
UNAME_S := $(shell uname -s)

archive: meta-scrub
	tar --exclude='.git*' --exclude='Makefile*' -cvjf $(dest)/$(WHOAMI)-$(YMD).tar.bz2 ./data ./meta ./LICENSE.md ./CONTRIBUTING.md ./README.md

bin:
	mkdir -p bin
ifeq ($(UNAME_S),Darwin)
	cd bin && curl -s -O https://raw.githubusercontent.com/whosonfirst/go-whosonfirst-meta/master/dist/darwin/wof-build-metafiles
	cd bin && curl -s -O https://raw.githubusercontent.com/whosonfirst/go-whosonfirst-meta/master/dist/darwin/wof-build-metafiles.sha256
	cd bin && curl -s -O https://raw.githubusercontent.com/whosonfirst/go-whosonfirst-concordances/master/dist/darwin/wof-build-concordances
	cd bin && curl -s -O https://raw.githubusercontent.com/whosonfirst/go-whosonfirst-concordances/master/dist/darwin/wof-build-concordances.sha256
	make bin-verify
else ifeq ($(UNAME_S),Linux)
	cd bin && curl -s -O https://raw.githubusercontent.com/whosonfirst/go-whosonfirst-meta/master/dist/linux/wof-build-metafiles
	cd bin && curl -s -O https://raw.githubusercontent.com/whosonfirst/go-whosonfirst-meta/master/dist/linux/wof-build-metafiles.sha256
	cd bin && curl -s -O https://raw.githubusercontent.com/whosonfirst/go-whosonfirst-concordances/master/dist/linux/wof-build-concordances
	cd bin && curl -s -O https://raw.githubusercontent.com/whosonfirst/go-whosonfirst-concordances/master/dist/linux/wof-build-concordances.sha256
	make bin-verify
else ifeq ($(UNAME_S),Windows)
	cd bin && curl -s -O https://raw.githubusercontent.com/whosonfirst/go-whosonfirst-meta/master/dist/windows/wof-build-metafiles
	cd bin && curl -s -O https://raw.githubusercontent.com/whosonfirst/go-whosonfirst-meta/master/dist/windows/wof-build-metafiles.sha256
	cd bin && curl -s -O https://raw.githubusercontent.com/whosonfirst/go-whosonfirst-concordances/master/dist/windows/wof-build-concordances
	cd bin && curl -s -O https://raw.githubusercontent.com/whosonfirst/go-whosonfirst-concordances/master/dist/windows/wof-build-concordances.sha256
	@echo "Skipping the SHA-256 verification, because Windows"
else
	echo "this OS is not supported yet"
	exit 1
endif

bin-verify:
	cd bin && shasum -a 256 -c wof-build-metafiles.sha256
	cd bin && shasum -a 256 -c wof-build-concordances.sha256
	chmod +x bin/wof-build-metafiles
	chmod +x bin/wof-build-concordances
	rm bin/wof-build-metafiles.sha256
	rm bin/wof-build-concordances.sha256

bundles:
	if test -z "$$BUNDLES"; then echo "missing BUNDLES arg"; exit 1; fi
	if test -z "$$BUCKET"; then echo "missing BUCKET arg"; exit 1; fi
ifeq ($(WHATAMI),)
	$(WOF_BUNDLE_PLACETYPES) -R $(WHEREAMI) -d $(BUNDLES) -i address,building,metroarea,postalcode,venue -S latest --aws-bucket $(BUCKET) --wof-clone $(WOF_CLONE_METAFILES)
else
	$(WOF_BUNDLE_PLACETYPES) -R $(WHEREAMI) -d $(BUNDLES) -p $(WHATAMI) -S latest --aws-bucket $(BUCKET) --wof-clone $(WOF_CLONE_METAFILES)
endif

# https://github.com/whosonfirst/go-whosonfirst-concordances
# Note: this does not bother to check whether the newly minted
# `wof-concordances-tmp.csv` file is the same as any existing
# `wof-concordances-latest.csv` file. It should but it doesn't.
# (20160420/thisisaaronland)

# https://github.com/whosonfirst/whosonfirst-data-utils/issues/2

concordances:
	test -s $(WOF_BUILD_CONCORDANCES) || make bin
	mkdir -p $(WHEREAMI)/meta
	$(WOF_BUILD_CONCORDANCES) -processes 100 -repo $(WHEREAMI)

count:
	find ./data -name '*.geojson' -print | wc -l

docs:
	curl -s -o LICENSE.md https://raw.githubusercontent.com/whosonfirst/whosonfirst-data-utils/master/docs/LICENSE-SHORT.md
	curl -s -o CONTRIBUTING.md https://raw.githubusercontent.com/whosonfirst/whosonfirst-data-utils/master/docs/CONTRIBUTING.md

githash:
	git log --pretty=format:'%H' -n 1

gitignore:
	curl -s -o .gitignore https://raw.githubusercontent.com/whosonfirst/whosonfirst-data-utils/master/git/dot-gitignore
	curl -s -o meta/.gitignore https://raw.githubusercontent.com/whosonfirst/whosonfirst-data-utils/master/git/dot-gitignore-meta

gitlf:
	if ! test -f .gitattributes; then touch .gitattributes; fi
ifeq ($(shell grep '*.geojson text eol=lf' .gitattributes | wc -l), 0)
	cp .gitattributes .gitattributes.tmp
	perl -pe 'chomp if eof' .gitattributes.tmp
	echo "*.geojson text eol=lf" >> .gitattributes.tmp
	mv .gitattributes.tmp .gitattributes
else
	@echo "Git linefeed hoohah already set"
endif

gitlfs-track-meta:
	git-lfs track meta/*-latest.csv

# https://internetarchive.readthedocs.org/en/latest/cli.html#upload
# https://internetarchive.readthedocs.org/en/latest/quickstart.html#configuring

ia:
	ia upload $(WHOAMI)-$(YMD) $(src)/$(WHOAMI)-$(YMD).tar.bz2 --metadata="title:$(WHOAMI)-$(YMD)" --metadata="licenseurl:http://creativecommons.org/licenses/by/4.0/" --metadata="date:$(YMD)" --metadata="subject:geo;mapzen;whosonfirst" --metadata="creator:Who's On First (Mapzen)"

internetarchive:
	$(MAKE) dest=$(src) archive
	$(MAKE) src=$(src) ia
	rm $(src)/$(WHOAMI)-$(YMD).tar.bz2

list-empty:
	find data -type d -empty -print

metafiles:
	test -s $(WOF_BUILD_METAFILES) || make bin
	mkdir -p $(WHEREAMI)/meta
ifeq ($(WHATAMI),)
	$(WOF_BUILD_METAFILES) -repo $(WHEREAMI) -placetypes address,building,constituency,metroarea,postalcode,venue
else
	$(WOF_BUILD_METAFILES) -repo $(WHEREAMI) -placetypes $(WHATAMI)
endif

meta-scrub:
	ls -a meta/*.csv | grep -v latest | xargs rm

postbuffer:
	git config http.postBuffer 104857600

# As in this: https://github.com/whosonfirst/git-whosonfirst-data

post-pull:
	./.git/hooks/pre-commit --start-commit $(commit)
	./.git/hooks/post-commit --start-commit $(commit)
	./.git/hooks/post-push --start-commit $(commit)

prune:
	git gc --aggressive --prune

rm-empty:
	find data -type d -empty -print -delete

setup:
	# Running one-time setup tasks...
	# --------
	# Configure the repository to disable oh-my-zsh’s Git status integration,
	# which performs poorly when working with large repos.
	# See: http://stackoverflow.com/questions/12765344/oh-my-zsh-slow-but-only-for-certain-git-repo
	git config --add oh-my-zsh.hide-status 1
	# --------
	# Okay, all done with setup!

# https://github.com/whosonfirst/py-mapzen-whosonfirst-search
# Note that this does not try to be at all intelligent. It is a
# straight clone in to ES for every record.
# (20160421/thisisaaronland)

sync-es:
	wof-es-index --source data --bulk --host $(host)

sync-fs:
	if test ! -d $(dest); then echo "$(dest) does not exist!"; exit 1; fi
	rsync -az data/ $(dest)

# https://github.com/whosonfirst/py-mapzen-whosonfirst-spatial

sync-pg:
	wof-spatial-index --source data --config $(config)

# https://github.com/whosonfirst/go-whosonfirst-s3
# Note that this does not try to be especially intelligent. It is a
# straight clone with only minimal HEAD/lastmodified checks
# (20160421/thisisaaronland)

# Also see the way we're passing data as a prefix? That's because we're
# using the data directory as the root so we need to make sure we prepend
# it to stuff before sending it to S3 because... well, let's just forget
# that ever happened okay (20160517/thisisaaronland)

sync-s3:
	wof-sync-dirs -root data -bucket whosonfirst.mapzen.com -prefix "data" -processes 64

update-makefile:
	curl -s -o Makefile https://raw.githubusercontent.com/whosonfirst/whosonfirst-data-utils/master/make/Makefile
ifeq ($(shell echo $(WHATAMI) | wc -l), 1)
	if test -f $(WHEREAMI)/Makefile.$(WHATAMI);then  echo "\n# appending Makefile.$(WHATAMI)\n\n" >> Makefile; cat $(WHEREAMI)/Makefile.$(WHATAMI) >> Makefile; fi
	if test -f $(WHEREAMI)/Makefile.$(WHATAMI).local;then  echo "\n# appending Makefile.$(WHATAMI).local\n\n" >> Makefile; cat $(WHEREAMI)/Makefile.$(WHATAMI).local >> Makefile; fi
endif
	if test -f $(WHEREAMI)/Makefile.local; then echo "\n# appending Makefile.local\n\n" >> Makefile; cat $(WHEREAMI)/Makefile.local >> Makefile; fi

wof-less:
	less `$(WOF_EXPAND) -prefix data $(id)`

wof-open:
	$(EDITOR) `$(WOF_EXPAND) -prefix data $(id)`

wof-path:
	$(WOF_EXPAND) -prefix data $(id)
