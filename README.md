# WABE.org Import Process
\- 2017-08-10

## Preparation
1. Remove data from `old_` that is already in `live`
2. Add _"Legacy Import"_ user in `wp_users`
3. Assign _"Legacy Import"_ user to `post_author` in `wp_posts`
4. Dump `old_` data from `import`
5. Fixup `term_id` to match `term_taxonomy_id` for (`1226` to `1250`)
6. FTP uploads from `import` - `post_type='wabe_person'` to `live`
7. Create `preview` branch on Pantheon
	1. Copy code from `player`
	2. Copy DB from `live`
	2. Copy Files from `live`

## Starting assets
1. Dump of the `old_` data tables from `import`
2. Uploads from `import` - `post_type='post'` uploads _(already on `live`)_
3. Uploads from `import` - `post_type='wabe_person'` 


## For Preview Only
1. Use terminus to copy DB from `live` to `preview` 
2. Use terminus to copy Files from `live` to `preview` 


## Repeatable Process 
- Run on `preview` or `live`
- `1` is `preview` only

1. Import `old_` data tables by running
2. `IMPORT` `old_` tables into `live` tables:
	
	a. `IMPORT` `old_` `post` records into `wp_` DB (`ID>=275000`)
	
	b. `IMPORT` `old_` `postmeta` records into `wp_` DB (`meta_id>=2,000,000`)

	c. `IMPORT` `old_` `terms` records into `wp_` DB (`term_id>=2000`)

	d. `IMPORT` `old_` `term_taxonomy` records into `wp_` DB (`term_taxonomy_id>=2000`)
	
	e. `IMPORT` `old_` `term_relationships` records into `wp_` DB

3. Run API to import XML for newer posts _(>= Aug 3rd)_
	
    1. `curl` the URL (path) `/npr-missing-story-xml`
    2. `curl` the URL (path) `/npr-import-authors`
    3. `curl` the URL (path) `/npr-image-attributions`
    4. `curl` the URL (path) `/npr-content-source`

