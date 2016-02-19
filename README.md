## Debugging

If there are councils that have been dismissed there will be a discrepancy
between the number of councils listed on the index page and the number scraped.
See the end of the debug output, for example:

> 79 councils listed
> 77 councils scraped

This scraper also checks the number of councillors collected against a number
listed on the page being scraper. See the debug output for things to check.

## Limitation

Because of some really nasty markup,
a councillor for Hindmarsh Shire Councilis missed.

This should be:

* id: "hindmarsh_shire_council/ronald_lowe"
* council: "Hindmarsh Shire Council"
* ward: "North"
* name: "Ronald Lowe"
* position: nil
* council_website: "http://www.hindmarsh.vic.gov.au"
