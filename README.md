# Magic Lab Website

Static site generator for university research lab website.

We use [Gulp](http://gulpjs.com/) to assemble content into static pages that can be served by a CDN. We make use of standard plugins to transpile, concatenate, minify, and render higher-level languages into servable HTML and CSS. Care is taken to choose high-level languages that will age well, such as [polyfill](http://en.wikipedia.org/wiki/Polyfill)s for backwards compatibility of recently established standards.

Versions of the generated site are stored in source control, which enables diff-based auditing and a push-to-deploy workflow. Push-to-deploy is supported by CDNs such as [GitHub Pages](https://pages.github.com/), and easy to set up on any host with ssh access [by writing a `post-receive` hook](http://nicolasgallagher.com/simple-git-deployment-strategy-for-static-sites/).

We store data in a [normalized](http://en.wikipedia.org/wiki/Database_normalization) Google Spreadsheet and use a custom plugin to feed it into the gulp workflow. It generates one HTML page for each worksheet.


### Installation

Install [Node.js](http://nodejs.org/download/) and run
    
    npm install

from the project directory. If you don't want to install `gulp` globally, add the local install to your path:

    export PATH="$PATH:./node_modules/.bin"


### Configuration

Gulp encourages a "code over configuration" style, so in many cases it is best to edit the gulpfile directly.

Some situational behavior is controlled by environment variables:

- `MINIFY`: Set to any non-empty value to enable minification of generated HTML and CSS.

- `PORT=8000`: Port to serve site on when using `gulp serve` and `gulp watch`.

- `GSS_ID`: ID of Google Spreadsheet to fetch data from.

- `GOOGLE_DRIVE_FOLDER_ID`: Set this to the folder where assets are stored.

- `OAUTH_CLIENT_ID`, `OAUTH_CLIENT_SECRET`, `OAUTH_REFRESH_TOKEN`: Set these to an app that has access to the assets folder.


### Usage

To generate the website from data and templates, run

    gulp build

then publish the `public` folder. (Use `publish.sh` to automatically commit that folder to the `gh-pages` branch.)

For development, run

    gulp watch

and navigate to [http://localhost:8000](http://localhost:8000). Changes made to source files should be reflected immediately in your browser.


### Content Management

Most common tasks can be accomplished by editing the spreadsheet and running `gulp build`.

- **To create a new page:**

    Create a new worksheet with the title you want for the page title. It will be converted into `kebab-case`. Currently there is no automatic site-map generation, so you will have to link to the new page manually.

- **To create a new section on a page:**

    Enter the section title you want in the "Section" column. Discontiguous sections will be grouped together, in the order of their first appearance.

- **To create a new data field:**

    Create a column with the field name in the first row, and write a CSS rule in `src/style/main.css` to display it. For a field named `xyz`, the created element will have class `.data-field-xyz`

- **To write custom HTML in a field:**

    Use [markdown syntax](http://daringfireball.net/projects/markdown/syntax).

- **To see what has changed between published revisions:**

    You can view diffs on the published branch using any general-purpose Git history visualizer, such as [SourceTree](http://www.sourcetreeapp.com/).

    We commit JSON data and rendered HTML to this branch, so a change on one worksheet would produce a change to the corresponding data file and HTML file.

### Spreadsheet to DOM Transformation

On each worksheet, rows are grouped by their "section" column. Within the section a div is created for each row. Each cell is transformed with [markdown](http://daringfireball.net/projects/markdown/) and placed into a div with a class derived from its column title. This makes it easy to write custom CSS to lay out specific fields on specific pages.

Some fields are treated specially:

- **Title**: GSS inserts a field by this name if there is not one already, so we hide it by default. To show it, set its `display` property to something other than `none` in the CSS.
- **Link**: This is automatically converted into a hyperlink, and combined with the **Name** field if both are present. This is often more convenient than using markdown to get the same result.
- **Picture**: This is automatically converted into an image in the "assets" folder.

For example, this data:

    Section         Name                Link                      Description
    Research Team   Mary-Anne Williams  http://themagiclab.org/   Director of the Magic Lab

transforms into this HTML:

    <body class="data-page-People">
        <h2>People</h2>
        <section class="data-section-research-team">
            <h3>Research Team</h3>
            <div class="data-item">
                <span class="data-field-name">
                    <a href="http://themagiclab.org/">Mary-Anne Williams</a>
                </span>
                <span class="data-field-description">
                    Director of the Magic Lab
                </span>
            </div>
        </section>
    </body>
