#!/usr/bin/env Rscript
##
##
## Ad-hoc package builder, follows logic in script in existing duck-deb repo
## Dirk Eddelbuettel, Nov 2026, GPL-2+

dir <- "~/git/opencode-deb/pkg"
if (dir.exists(dir)) setwd(dir) else q(save="no")

url <- "https://api.github.com/repos/anomalyco/opencode/releases"
res <- jsonlite::fromJSON(url)
releases <- gsub("^v", "", res$tag_name)    # as tag_name is "v1.1.2" etc
## opencode special
releases <- releases[ !grepl("process-daemon", releases) ]
release <- releases[1]

## old
#url <- "https://registry.npmjs.org/opencode-ai/latest"
#res <- jsonlite::fromJSON(url)
#ver <- res$version
#release <- paste0("v", ver)

#https://github.com/anomalyco/opencode/releases/download/v2.2.6/opencode-linux-x64.tar.gz


chnglg <- readLines("debian/changelog")
chnglg <- chnglg[grepl("^opencode \\(.*\\).*", chnglg)]
pkgs <- gsub(".*\\((.*)\\).*", "\\1", chnglg)


if (length(pkgs) > 0 && release == pkgs[1])
    q(save="no")

binfile <- file.path("https://github.com/anomalyco/opencode/releases/download",
                     paste0("v", release), "opencode-linux-x64.tar.gz")
#print(binfile)
tgt <- basename(binfile)

if (!file.exists(tgt)) {
    download.file(binfile, tgt, quiet=TRUE)
    cat("Downloaded", tgt, "\n")
}

Sys.setenv(EMAIL="edd@debian.org")
cmd <- sprintf("dch --package opencode --newversion %s --distribution noble 'New version'", release)
system(cmd)

cmd <- "dpkg-buildpackage -us -uc -rfakeroot -tc"
system(cmd)

unlink(tgt)

newdeb <- paste0("../opencode_", ver, "_amd64.deb")
if (file.exists(newdeb))
    res <- file.copy(newdeb, "~/git/ppa-rstudio/docs")

#olddeb <- paste0("../opencode_", pkgs[1], "_amd64.deb")
#if (file.exists(olddeb)) {
#    cat("Deleting", olddeb, "\n")
#    res <- file.remove(olddeb)
#}

if (length(pkgs) >= 2) {
    setwd("..")
    f <- list.files(pattern=paste0("*", pkgs[2], "*"), full.names = TRUE)
    unlink(f)
}
