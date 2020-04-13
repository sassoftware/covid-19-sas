# An overview of the steps I took to move the repository on April 10th, 2020:

## Fork both to my personal account statmike:
- from: https://github.com/sassoftware/covid-19-sas
    - to: https://github.com/statmike/covid-19-sas
- from: https://github.com/dochixson/covid
    - to: https://github.com/statmike/covid

## Cloned both to my computer /github/forks

## Prep statmike/covid
at terminal:
- mkdir ccf
- git mv file/folder ccf (do for each file, folder, except license, even the readme)
- Add new readme.md at the top level that points to new location at sassoftware/covid-19-sas
- commit to fork and push to origin, GitHub

## Copy CCF folder from statmike/covid to statmike/covid-19-sas with history
at terminal:
- first, store a copy of license and readme.md in statmike/covid-19-sas to hold for putting back after the move in github/forks
- go to /forks/covid-19-sas folder
- git remote add modified-source ../covid
- git pull modified-source master —allow-unrelated-histories
    - vi editor opens, add merge note, esc, :x
- git remote rm modified-source
- make sure license in main folder and ccf is right
- make sure readme in main folder is right
- make sure ccf readme correctly point to sassoftware

## Pull forks back to repositories
- Pull statmike/covid-19-sas to sassoftware/covid-19-sas
- Pull statmike/covid to dochickson/covid

## Drop the project content from old repository
- Drop ccf folder on dochickson/covid

## Links 
- https://medium.com/@ayushya/move-directory-from-one-repository-to-another-preserving-git-history-d210fa049d4b
- https://github.community/t5/How-to-use-Git-and-GitHub/Adding-a-folder-from-one-repo-to-another/td-p/5425
