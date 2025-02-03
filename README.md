# Markdown book skeleton
Skeleton files for writing a book using markdown. Typora is recommended

Copy the book-example folder to book

## Requirements

You need to have make installed. To setup your environment just run `make environment` to install all packages. 

In some cases the only package that you need to install manually is pandoc. The make environment script does install pandoc but unfortunately the pandoc version in most repo's is horribly out of date. You will need at least version `2.19.2`. You can check your installed version with `pandoc -v`. If your installed version is recent enough you will not need to perform this step.

If your version is out of date just manually install pandoc:

```
# navigate to https://github.com/jgm/pandoc/releases/latest and copy the version for your architecture
cd /tmp
wget <dl link for pandoc>
sudo dpkg -i <downloaded pandoc>
```

## How-to

```
mkdir my-new-awesome-book
git clone https://github.com/epiecs/markdown-pandoc-book-template.git .
cp -r book-example/ book
cd book
```

Install needed packages

```
sudo tlmgr update --self
```

Then initialize your seperate git repo in the book folder. Be sure to check and modify `meta.yml` and `pandoc.yml`


## Folders

- All chapters are in the `book/chapters` folder.
- All front matter (thanks etc) is in the `book/front_matter folder
- All back matter (appendix etc) is in the `book/back_matter folder
    - All back matter content will have no chapter numbering but will be included in the toc

## Usage

You need make to use this skeleton. Use `make book` to build the entire book. This wil render a pdf, epub, html and docx version of your book. Everything will be put in the `build` folder.

The difference between the print and web pdf is that the print pfd includes extra blank pages to make sure that a new chapter starts on an uneven page

## Make commands

`make environment` installs all programs

`make markdown` combines all chapters and runs script to build 1 markdown file

`make <epub|html|pdf-web|pdf-print|docx>` generate a specific format

`make book` and `make all` generates all formats

`make pdf` generates web and print pdf's

`make clean` verwijdert de gegenereerde files

Be sure to check out the makefile to tweak everything to your needs

The default folder is `book` within the project folder. You can also specify a remote `book` folder with `make pdf-web BOOK_FOLDER=../my/folder/for/my/books/book`. Another option is to specify the filename the same way with `OUTPUT_FILENAME=myname`

## Book and pandoc settings

All book settings can be found in `meta.yaml`
All pandoc settings can be found in `pandoc.yaml`

## Includes

If make gives you trouble just run make clean first.
