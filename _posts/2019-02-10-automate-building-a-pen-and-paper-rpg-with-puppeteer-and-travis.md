---
layout: post
title:  "Automate building a pen & paper RPG with Puppeteer and Travis"
date:   2019-02-10 15:00:00 +0000
---

A couple of my friends and I have a podcast where we play stupid one page RPGs called [GORM](https://gormpodcast.com). Recently we have started dabbling with creating our own RPGs to varying success, my first attempt "[Law, Order and Sentencing](https://gormpodcast.com/rpgs/Law%20Order%20And%20Sentencing.pdf)" has myriad issues [^1] [^2] but I want to focus in this post on the actual creation of the PDF and how I have hopefully improved the process for my second attempt "[Pyramids](https://pyramids.gormpodcast.com/)". 

# The Failed First Attempt

I originally drafted LOaS in a word document which I sent to a friend of mine who I knew had an Adobe Creative Cloud subscription and access to its InDesign publishing offering. I think he did a really good job on the first draft with formatting.

![The LOaS PDF](/assets/postmedia/LOaS.PNG)

As this was a first draft I had not thoroughly proof read my original document and so of course quite a few grammatical errors and typos got through. This lead me to my first publishing epiphany: __don't send the first draft to get the fancy formatting__. Now I would need to make a list of changes to send to my friend for him to update, heaven forbid I add a sentence and he has to reflow the whole document. Luckily this wasn't an issue my friend had to worry about as by this time his Adobe CC subscription had expired and I wasn't going to shell out £50/mo to get it myself. The end result is that we just kept the crap first version and will try to do better next time. 

It should be said that I am aware that these are problems that have probably already been solved a thousand times before in the publishing industry, but as I am not a publisher I have neither the knowledge to know exactly what it is that I want or likely the money to pay for it when I find it. No I am not a publisher, but I am a software engineer who takes particular interest in build pipelines and I was pretty sure I could automate the build of my PDF from code.

# Planning To Build A PDF

I soon had another idea for a micro RPG which was going to be called "Pyramids" because it uses d4s for rolls, pretty much all my ideas start out as puns for better or worse. I knew this time I was going to have to make the PDF myself so I formulated the following plan:

1. Think of the rules, a solid first step.
2. Write those rules down somewhere and discuss them with others.
3. Stick the rules in an HTML document.
4. Format the rules using CSS.
6. Version control the document in git so I can keep track of changes between versions. 
5. Somehow convert my HTML document to PDF as part of an automated build.

Steps 3-6 are where the automation happens. 

# Build The Foundation

First things first put the rules in HTML. Now at this point some of you are probably annoyed that I decided to use HTML instead of a more fit for purpose [typesetting language](https://en.wikipedia.org/wiki/LaTeX), I'll discuss why later on but for now I'll give the short reason: I already know HTML. At this point I already knew I wanted two pages with two columns each so I just made some divs with the class `page` and `column` and wrote it all down.

```html
<div class="page">
  <div class="column">
    <h1>Pyramids</h1>
    ...
    </div>
</div>
```
# Add A Lick Of Paint

Second things second give it some _style_ with CSS. I grabbed a font from Google Fonts that [looked kind of handwritten](https://fonts.google.com/specimen/Kalam), prettied up the tables and made sure my columns were actually columnar then opened it up in my browser and was happy. I then "printed" my document to a PDF and was very sad. Text was overlapping while either tiny or huge with weird spacing between elements. Oh and my background wasn't there. Not great. I decided at this point that I was going to go "PDF first" in my styling and converted all the sizes to inches which made a big difference in legibility. However, before I got sucked further into the awful world of CSS sizing whack-a-mole I decided to make the actual process of printing the PDF smoother so I could iterate faster.

# Bring Out The Power Tools

I know that the product I work on at my day job uses (used?) [PhantomJS](http://phantomjs.org/) as its headless browser for PDF printing so I started my search there. Turns out PhantomJS is [no longer maintained](https://github.com/ariya/phantomjs/issues/15344) and seemingly everyone now uses [Headless Chrome](https://developers.google.com/web/updates/2017/04/headless-chrome). Great! I had chrome already so I gave it a go.

```
chrome.exe --headless --print-to-pdf pyramids.html
```

Nothing happens. [^3] 

After some googling it turns out I was doing a few things wrong, mostly because I am a Windows user. 
1. It needs to have administrator privileges. (Why?)
2. I need to specify the output path.
3. It needs a URL to print e.g. `file:///D:/pyramids.html`

```
chrome.exe --headless --print-to-pdf="D:\pyramids.pdf" file:///D:/pyramids.html
```
Awww yeah a PDF appeared, lets have a look:
![Headless Chrome CLI Attempt](/assets/postmedia/PyramidsHeadlessChromeCLI.PNG)

So clearly I had done something wrong here. Aside from the obvious lack of text it would also be nice to remove the auto-generated header and footer. Some trawling through the Headless Chrome documentation made it clear that the CLI didn't have many options for PDF printing and I wouldn't be able to get what I wanted. However, the CLI is not the only interface for Headless Chrome and it became clear that I should actually be using its DevTools protocol through the node package [Puppeteer](https://github.com/GoogleChrome/puppeteer).

As is often the case I managed to take 1 step forward 2 steps back when attempting to print with Puppeteer with my first iteration of print.js:

```javascript
const puppeteer = require('puppeteer');
const path = require("path");
var absoluteHtmlPath = path.resolve("pyramids.html");
(async () => {
	const browser = await puppeteer.launch();
	const page = await browser.newPage();
	await page.goto('file:///' + absoluteHtmlPath);
	await page.pdf({ path: "pyramids.pdf", format: 'A4' });

	await browser.close();
})();
```
This code actually managed to print less than the CLI. The background picture is gone along with the ugly header and footer for a small win. I'd add a picture but its just a rectangle of white. So why was nothing appearing? The background picture was easy enough, the `pdf` function has a `printBackground` parameter that defaults to false, setting that true got me back to the same look as the CLI attempt. The body of the text itself was a more tricky proposition. I figured it had something to do with the fact that I was using a web font which I confirmed by switching the font to Arial. CSS is not my strong suit so though perhaps I was referencing the web font incorrectly for print, perhaps I needed to include it in a media query. In the end it turned out it wasn't my poor CSS skills, it was actually because Chrome was printing the PDF before it had downloaded the font. You can make the page wait for fonts to be ready with `page.evaluateHandle('document.fonts.ready')`. My final working print.js:

```javascript
const puppeteer = require('puppeteer');
const path = require("path");
var absoluteHtmlPath = path.resolve("pyramids.html");
(async () => {
	const browser = await puppeteer.launch();
	const page = await browser.newPage();
	await page.goto('file:///' + absoluteHtmlPath);
	await page.evaluateHandle('document.fonts.ready');
	await page.pdf({ path: "pyramids.pdf", format: 'A4', printBackground: true });

	await browser.close();
})();
```

And an example of its glorious output after some HTML reflow and CSS updates:
![Headless Chrome Puppeteer Attempt](/assets/postmedia/PyramidsHeadlessChromePuppeteer.PNG)

# Hiring Another Guy To Do It For You

Once I had an actual working print script and something to print it was time to automate it so I never had to do it again. My go to build service for my public git repositories is [Travis](https://travis-ci.org/) because it's free and easy enough to set up even with some strange idiosyncracies. Travis already has node as one of it's supported languages so the implementation was pretty trivial:

```yaml
language: node_js
node_js: 
  - node
script: node print.js site/index.html site/pyramids.pdf
deploy:
  - provider: releases
    skip_cleanup: true
    on:
      tags: true
    api_key: $GITHUB_API_KEY
    file: 
      - site/pyramids.pdf
```

This template does an `npm install` in the background to get puppeteer then runs my build script print.js to generate the PDF before finally uploading it to GitHub releases if it is a tagged commit. 

# Closing Thoughts 

Now that I have automated the build making small changes for spelling or grammatical mistakes has been trivial. Larger changes does require me to reflow the document otherwise text can be cut off or overlapping on the next page which isn't ideal. I suspect LaTeX or similar would remedy this problem but I didn't want to learn a new language for my first attempt at something like this. Furthermore my choice to use HTML has allowed me to publish the same document as a website using my [static site Terraform module](https://github.com/george-richardson/terraform_s3_cloudfront_static_site) and some CSS media queries to change the formatting for screen. I think I have created a good base here which will hopefully speed me up for my next micro RPG.

Find the final rules for Pyramids [here](https://pyramids.gormpodcast.com/pyramids.pdf), or check out the [website](https://pyramids.gormpodcast.com/). Check out the source code [on GitHub](https://github.com/george-richardson/pyramids_rpg). If you want to listen to someone play it subscribe to my podcast [GORM](https://gormpodcast.com) to be alerted when the next episode comes out.

[^1]: [Listen to us play it](http://feed.gormpodcast.com/e/15-law-order-and-sentencing-part-1/).
[^2]: Tom's first attempt [Office Talk](https://gormpodcast.com/rpgs/Office-Talk.pdf) was much better.
[^3]: Well it actually starts a Chrome.exe process in the background and never closes it.