#!make
CURRENT_BRANCH = $(shell git name-rev --name-only HEAD)
IN_DIR = content
OUT_DIR = out
STATIC_DIRS = static/ out/html/static/
HTML_DIR = $(OUT_DIR)/html
PDF_DIR = $(OUT_DIR)/pdf
DOCX_DIR = $(OUT_DIR)/docx
DEPLOY_BRANCH = gh-pages
DEPLOY_DELETE_DIRS = out content bin templates
DEPLOY_DELETE_FILES = Makefile README.md LICENSE.md installation_ko.md

ifndef CURRENT_BRANCH
	CURRENT_BRANCH = $(error Could not get current branch.)
endif

ifeq ($(shell echo "check_quotes"),"check_quotes")
	WINDOWS := yes
else
	WINDOWS := no
endif

ifeq ($(WINDOWS),yes)
	mkdir = mkdir $(subst /,\,$(1)) > nul 2>&1 || (exit 0)
	cp = cp $(subst /,\,$(1)) > nul 2>&1 || (exit 0)
	rm = $(wordlist 2,65535,$(foreach FILE,$(subst /,\,$(1)),& del $(FILE) > nul 2>&1)) || (exit 0)
	rmdir = rmdir $(subst /,\,$(1)) > nul 2>&1 || (exit 0)
	echo = echo $(1)
	DATE = $(shell date /t)
else
	mkdir = mkdir -p $(1)
	cp = cp -r $(1)
	rm = rm -rf $(1) > /dev/null 2>&1 || true
	rmdir = rm -rf $(1) > /dev/null 2>&1 || true
	echo = echo "$(1)"
	DATE = $(shell date +%FT)
endif

all: html pdf docx

html:
	$(call mkdir, $(OUT_DIR))
	$(call cp, $(STATIC_DIRS))
	$(call mkdir, $(HTML_DIR))
	for f in $(IN_DIR)/*.md; do \
		FILE_NAME=`basename $$f | sed 's/.md//g'`; \
		echo $$FILE_NAME.html; \
		pandoc --section-divs -s $(IN_DIR)/$$FILE_NAME.md -H ./templates/header.html -c static/$$FILE_NAME.css -o ${HTML_DIR}/$$FILE_NAME.html; \
	done

docx:
	$(call mkdir, $(DOCX_DIR))
	for f in $(IN_DIR)/*.md; do \
		FILE_NAME=`basename $$f | sed 's/.md//g'`; \
		echo $$FILE_NAME.docx; \
		pandoc --standalone $$SMART $$f --output $(DOCX_DIR)/$$FILE_NAME.docx; \
	done

pdf: html
	$(call mkdir, ./$(PDF_DIR)/)
	for f in $(IN_DIR)/*.md; do \
		FILE_NAME=`basename $$f | sed 's/.md//g'`; \
		echo $$FILE_NAME.pdf; \
		phantomjs bin/rasterize.js ${HTML_DIR}/resume.html ${PDF_DIR}/$$FILE_NAME.pdf 0.7; \
	done

gh-pages:
	git checkout -b ${DEPLOY_BRANCH}
	git push --set-upstream origin ${DEPLOY_BRANCH}
	git checkout ${CURRENT_BRANCH}

del-gh-pages:
	git push --delete origin ${DEPLOY_BRANCH}
	git branch -D ${DEPLOY_BRANCH}

deploy: html
	@echo "Cleaning $(BUILD_DIR)"
	pandoc --section-divs -s ./content/resume.md -H ./templates/header.html -c static/resume.css -o index.html
	git checkout ${DEPLOY_BRANCH}
	$(call rmdir, $(DEPLOY_DELETE_DIRS))		
	$(call rm, $(DEPLOY_DELETE_FILES))
	-git add index.html static
	-git add -u
	-git commit -m 'Automatic build commit on $(DATE).'
	git push
	git checkout master

commit: build
	git checkout master
	git add .
	-git commit -m 'Automatic commit on $(DATE).'
	git push

clean:
	${rm} ${OUT_DIR}