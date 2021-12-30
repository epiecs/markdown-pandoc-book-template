#! /usr/bin/python3

import re
import sys
import yaml
from typing import List

def splitchapters(data:str, chapters:List) -> str:
    """
    Splits chapters. All chapters defined in chapters[] will receive a /newpage 
    before the chapter. The chapter following will also receive a /newpage to start 
    on a new page.

    Chapter name is case sensitive.

    Args:
        data (str): textual data
        chapters (List): List containing chapter names

    Returns:
        str: processed data
    """

    # First insert a /newpage before
    for chapter in chapters:
        regex_chapter = fr"^#+ {chapter}"

        matches = set(re.findall(regex_chapter, data, flags=re.M))


        for index, match in enumerate(matches):
            data = re.sub(fr"^{re.escape(match)}", f"\\\\newpage \n{match}", data, flags=re.M)

    """
        Loop all chapters, If we find a chapter that is in the list we mark it and 
        look for the next chapter that starts at the same level or higher. When 
        found we inserta \newpage
    """
    
    regex_all_chapters = r"(?P<heading>#{1,6}) (?P<title>.*)"
    lookup_level = None

    for match in re.finditer(regex_all_chapters, data):
        groups = match.groupdict()

        # If its one of the titles we are looking for calculate the 
        # heading level and continue
        if groups['title'] in chapters:
            lookup_level = len(groups['heading'])
            continue

        current_level = len(groups['heading'])

        # if the heading level is smaller or equal we split
        if lookup_level and current_level <= lookup_level:
            data = re.sub(f"{groups['heading']} {groups['title']}", f"\\\\newpage \n{groups['heading']} {groups['title']}", data)
            lookup_level = None

    return data

def fixfootnotes(data:str) -> str:
    """
    fix all footnotes to be numerically correct

    Args:
        data (str): textual data

    Returns:
        str: processed data
    """   
    
    """
        We have to work in 2 passes so that we don't overwrite the next
        footnote in the document. So if we have numerical matches and we 
        start a normal write cycle we would overwrite the value with the 
        value of the next match. So 1 would be overwritten by 2. etc...

        so we take an intermediary step where we first use footnote-<index>
        in order to have a decent numerical baseline. Afterwards we overwrite
        it with the correct number.

        We match [^<text>] where it is not the beginning of the line.

        This function expects that the footnote in the text and the footnote
        itself have the same tag.

        TODO indien meerdere files een nummer hergebruiken is er een issue
        Best enkel de eerste match aanpassen, non greedy

        Case: Stel dat chapter 1 een note heeft met nr 14 en chapter 2 ook.
        Dan worden beide aangepast omdat de nummer hetzelfde is in de match
    """

    matches = re.findall(r".(\[\^[a-zA-Z0-9-_ ]+\])", data)
    for index, match in enumerate(matches):
        data = re.sub(re.escape(match), f"[^footnote-{index}]", data)

    matches = re.findall(r".(\[\^[a-zA-Z0-9-_ ]+\])", data)
    for index, match in enumerate(matches):
        data = re.sub(re.escape(match), f"[^{index + 1}]", data)

    return data

def defaultimagesettings(data:str, width:int = 60) -> str:
    
    regex_images = r"(\(resources/images/[\w\s/\-\.]+\))\s*\n$"

    data = re.sub(regex_images, fr"\g<1>{{width={width}%}}\n", data, flags=re.MULTILINE)

    return data

# Bijv, Bijv., bijv en bijv. fixen

with open('meta.yml', 'r') as yaml_file:
    meta_settings = yaml.load(yaml_file, Loader=yaml.SafeLoader)

with open(sys.argv[1], "r+") as file:
    data = file.read()

    data = splitchapters(data, ["Oefeningen"])
    data = fixfootnotes(data)
    data = defaultimagesettings(data)

    file.seek(0)
    file.write(data)
    file.truncate()
