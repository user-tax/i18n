#!/usr/bin/env coffee

> @user.tax/i18n

do =>
  i18n process.cwd()
  return
#console.log cookie2dict 'I=1665481017; test=1665492012'

###
> ./lib/render:

template = 'Example text: ${text}'
result = template.render {
  text: 'Foo Boo'
}
console.log result
###
