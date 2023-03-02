#!/usr/bin/env coffee

> fs > existsSync
  path > dirname join basename
  ./yml.js > translateYmlDir
  ./md.js > translateMd
  @u7/yml/Yml.js
  get_default:
  ./LANG_LI.js
  @u7/walk
  chalk

{gray,yellowBright} = chalk

< default main = (
  now
  hook={
    yml:(dir, default_lang)=>
    md:(dir, to, fp)=>
  }
)=>

  from_to = new Map
  to_from = new Map

  loop
    dir = dirname now
    if existsSync join now, 'i18n.yml'
      {i18n:conf} = Yml(now)
      for [k,v] from Object.entries(conf)
        if v
          for i from v.split ' '
            from_to.set i, k
            to_from.get_default(k,[]).push i
        else
          from_to.set undefined, k
      break
    if dir == now
      return
    now = dir

  default_lang = from_to.get()
  from_to.delete()

  li = to_from.get 'zh'
  if li
    li.push 'zh-TW'
  to_lang = new Set()
  for li from to_from.values()
    for i from li
      to_lang.add i

  now_len = now.length

  for await fp from walk(
    now
    (d)=>
      ['node_modules','.git'].includes basename d
  )
    rfp = fp[now_len..]
    dir = dirname(fp)
    pos = rfp.indexOf('/i18n/')
    if pos < 0
      pos = rfp.indexOf('.i18n/')
    if ~ pos
      if fp[dir.length+1..] == default_lang+'.yml'
        console.log yellowBright "\n❯ #{dir} translate begin"
        await translateYmlDir dir, from_to, default_lang
        await hook.yml dir, default_lang
        console.log gray "❯ #{dir} translated\n"
      else if fp.endsWith('.md')
        mdfp = rfp[pos+6..]
        p = mdfp.lastIndexOf('/')
        if ~ p
          rfp = dirname(rfp)
          lang = basename rfp
          workdir = now+dirname(rfp)

          tran = (i)=>
            await translateMd workdir, mdfp[p..], lang, i
            hook.md workdir, lang, i
            return
          if lang == default_lang
            for i from LANG_LI
              if not to_lang.has i
                await tran(i)
          else
            li = to_from.get lang
            if li
              for i from li
                await tran(i)

  return

