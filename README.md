# Steno

Steno is an HTML5 webapp used by [Openbylaws.org.za](http://openbylaws.org.za) to capture by-laws and process them into XML for use on the website.

Anyone can use the app running at [steno.openbylaws.org.za](http://steno.openbylaws.org.za).

# How to use Steno

1. Get a PDF or other version of the by-law to parse
2. Visit [steno.openbylaws.org.za](http://steno.openbylaws.org.za)
3. Enter the full title of the by-law and the region it applies to
4. Choose a short name. This will be used in filenames and should be all lowercase and not have any spaces.
5. Enter the gazette the by-law was published in, its number and date.
6. Choose the title format the by-law uses
7. Click `Looks good, next step`
8. Enter the plain-text of the by-law into the text box.
9. Click `Parse text`
10. Steno will show you an errors it finds while trying to parse the text.
11. Use the HTML preview on the right to check that the by-law parsed sanely. Look for issues such as broken lists, missed headings and unnecessary newlines.
12. Make corrections to the plain-text and click `Parse text` until you're happy
13. Click `Looks good, next step` to view the XML.
14. Edit the XML as necessary and click `Preview` until you're happy.
15. Click `Looks good, next step` to go to the final step.
16. Click `Save to Github` to save the file to Github and send a pull request.

# Saving to Github

You need to authorise Steno as a Github application. It will prompt you to do this when you first try to save to Github.

Steno will create a fork of the [za-by-laws](https://github.com/longhotsummer/za-by-laws) repository if you don't already have on. It will then save the new file to a new branch based on the short name of the by-law and submit a pull request.

You can safely go back, edit the document or XML, and click `Save to Github` again. 

# How Steno works

Steno's goal is to lower the bar for taking by-laws in plain-text (generally cut-and-pasted from a PDF) and transform them into [Akoma Ntoso](www.akomantoso.org) XML for use on the openbylaws.org.za website.

Steno has a grammar which does its best to make sense of a plain text version of the by-law. It finds structure such as lists, nested lists, sections, parts and chapters.

# Developing and contributing

We welcome pull requests!

Steno is a [Sinatra](http://www.sinatrarb.com/) ruby app. To install and run it locally,

1. clone the git repo
2. `bundle install`
3. rackup

# Production

Steno runs on heroku:

1. `git remote add heroku git@heroku.com:steno-openbylaws.git`
2. `git push`
