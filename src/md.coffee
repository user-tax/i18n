#!/usr/bin/env coffee

> ./j2f.js
  ./defrag.js
  @u7/tran > tranHtml
  @u7/binmap > BinMap
  @u7/blake3 > blake3Hash
  @u7/read
  @u7/u8 > u8eq
  @u7/utf8/utf8e.js
  @u7/utf8/utf8d.js
  @u7/write
  assert > strict:assert
  fs > existsSync readFileSync
  @u7/htm2md
  @u7/md2htm
  path > join

C_STYLE_COMMENT = /\/\*[\s\S]*?\*\/|([^:\/\/])\/\/.*$/gm

cStyleComment = (txt, translate)=>
  li = []

  txt.replace(
    C_STYLE_COMMENT
    (match)=>
      if match.startsWith '/*'
        li.push match[2...-2]
      else
        pos = match.indexOf("//")
        li.push match[pos+2..]
      return ''
  )

  if not li.length
    return txt

  li = (
    await translate(i) for i from li
  )

  txt.replace(
    C_STYLE_COMMENT
    (match, mlc, slc)=>
      if match.startsWith '/*'
        return "/*"+li.shift()+"*/"
      else
        pos = match.indexOf("//")
        return match[...pos+2]+li.shift()
      match
  )

comment = {
  rust:cStyleComment
}


# TODO
translate_comment = (markdown, translate)=>
  li = markdown.split("\n")

  out = []
  code = false
  code_li = []

  for line in li
    if code == false
      out.push line
      pos = line.indexOf("```")
      if pos+1
        _code = line[pos+3..].trim()
        if _code of comment
          code = _code
    else
      if line.indexOf("```") + 1
        out.push await comment[code] code_li.join("\n"),translate
        out.push line
        code = false
      else
        code_li.push(line)
  return out.join("\n")

md_html_li = (md)=>
  pre = ""
  if md.startsWith("---\n")
    end = md.indexOf("\n---\n",4)
    if end > 0
      end += 5
      pre = md[..end]
      md = md[end+1..]

  html = await md2htm md

  pre_code = []
  html = html.replace(
    /\<pre\>\<code[^<]+\<\/code\>\<\/pre\>/g
    (s)=>
      pre_code.push s
      "<img #{pre_code.length-1}>"
  )

  pli = html.split('</p>')
  t = pli.pop()
  li = []
  for i from pli
    li.push i+'</p>'
  li.push t

  [pre, li, md, pre_code]


tran = (dir, file, md, to, from_lang)=>
  [pre,li,_,pre_code] = await md_html_li md

  hashli = li.map (i)=>
    blake3Hash utf8e i

  cache_fp = join dir,from_lang,'.i18n',file.slice(0,-3)+'.'+to

  if existsSync cache_fp
    cache = BinMap.load readFileSync cache_fp
  else
    cache = new BinMap

  ili = []
  pli = []
  out = []

  n = li.length
  for i,p in li
    if i.trim()
      hash = hashli[p]
      r = cache.get(hash)
      if r
        --n
        out[p] = utf8d r
        continue
      ili.push i
      pli.push p
    else
      --n
      out[p] = i

  out_fp = dir+to+'/'+file
  if n == 0
    if existsSync out_fp
      [_pre,_li,_md, _pre_code] = await md_html_li read out_fp
      if _li.length == li.length
        + change

        for i,p in hashli
          v = cache.get(i)
          if v
            e = utf8e _li[p]
            if not u8eq(v,e)
              change = 1
              cache.set i,e

        if change
          console.log from_lang,'→',out_fp,'update cache'
          write(
            cache_fp
            cache.dump()
          )
        + w
        if _pre != pre
          w = 1
        else if _pre_code.length != pre_code.length
          w = 1
        else
          for i,p in _pre_code
            if i!=pre_code[p]
              w = 1
              break
        if not w
          return

  console.log from_lang,'→',out_fp
  n = 0
  for await i from tranHtml(ili, to, from_lang)
    p = pli[n++]
    out[p] = i

  html = out.join('').replace(
    /<img (\d+)>/g
    (_, d)=>
      pre_code[d-0]
  )
  # TODO: 翻译注释，先不搞，以后再说
  #txt = await translate_comment(
  #  txt
  #  (t)=>
  #    if deepl.source_lang == "ZH"
  #      if /^[\x00-\x7F]*$/.test(t)
  #        return t
  #    deepl.txt(t,target_lang)
  #)
  out_txt = pre+defrag(
    to, htm2md(html), md
  )

  write(
    out_fp
    out_txt
  )

  li = (await md_html_li out_txt)[1]
  assert(li.length==hashli.length)
  cache = new BinMap
  for i,pos in li
    cache.set(hashli[pos],utf8e i)

  write(
    cache_fp
    cache.dump()
  )
  return

< translateMd = (dir,file,src,to)=>
  workdir = dir+src
  fp = workdir+'/'+file
  md = read fp

  if to == 'zh-TW' and src == 'zh'
    write(
      dir+to+'/'+file
      j2f md
    )
  else
    await tran dir,file,md,to,src

  return
