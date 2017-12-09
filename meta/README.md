# meta files

_So-called "meta" (and concordances) files used to be bundled with each Who's On First repository but were fazed out in December, 2017 because they were too large and burdomsome. Instead they were replaced with pre-compiled binary tools (for Linux, OS X and Windows) to generate the files on demand._

To generate "meta" files `cd` in to the root directory of this repository and type `make metafiles`. A new meta file will be generated titled `meta/wof-{PLACETYPE-AND-MAYBE-COUNTRY-AND-REGION}-latest.csv`

To generate "concordances" files `cd` in to the root directory of this repository and type `make metafiles`. A new concordances file will be generated title `meta/wof-{PLACETYPE-AND-MAYBE-COUNTRY-AND-REGION}-concordances-latest.csv`

There is also a Git hook to automatically regenerate both the "meta" and "concordances" files. This can	be installed by typing `make install-hooks`.

You can update the tools used to generate the meta files and concordances files by typing `make update-utils`.

## See also

* https://github.com/whosonfirst/go-whosonfirst-meta
* https://github.com/whosonfirst/go-whosonfirst-concordances