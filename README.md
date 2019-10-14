![image showing airtable](http://reiler.net/goodreads-airtable.png)

# aws-lambda-goodreads-airtable
Fetch your "read", "to-read", and "currently-reading" shelves from Goodreads and sync with an Airtable.
Won't work by default unless Airtable is setup with correct associations and attributes.

Remember to add your own Goodreads and Airtable API keys.

[Example](https://airtable.com/shrbnNOGzXUakrXMj/tblpA7w5uCTdnEWrt/viwNqVN94B5r9jAUY?blocks=hide)

Based on: [https://github.com/Evilbits/Goodreads-Airtable](https://github.com/Evilbits/Goodreads-Airtable)

### Usage

1. Setup Airtable.
2. Create AWS Lambda function with the following environment variables:

```
GOODREADS_KEY=""
GOODREADS_SECRET=""
AIRTABLE_KEY=""
```

3. run `make`
