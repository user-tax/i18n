#!/usr/bin/env coffee

> ./j2f.js
  ./defrag.js
  ./tran.js > tranHtml
  @u7/binmap > BinMap
  @u7/blake3 > blake3Hash
  @u7/read
  @u7/u8 > u8eq
  @u7/utf8 > utf8e utf8d
  @u7/write
  assert > strict:assert
  cmark-gfm:cmark
  fs > existsSync readFileSync
  html-entities > encode
  path > join
  turndown:TurndownService

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

TurndownService.prototype.escape = (txt)=>txt

turndownService = new TurndownService {
  headingStyle:"atx"
  hr: '---'
  codeBlockStyle: "fenced"
}

turndownService.addRule 'br',
  filter:'br'
  replacement: (content, node, options) ->
    li = ['<br']
    for i from node.attributes
      li.push ' '+i.localName
    li.join('')+'>'

turndownService.addRule 'listItem',
  filter: 'li'
  replacement: (content, node, options) ->
    content = content.replace(/^\n+/, '').replace(/\n+$/, '\n').replace(/\n/gm, '\n  ')
    # indent
    prefix = options.bulletListMarker + ' '
    parent = node.parentNode
    if parent.nodeName == 'OL'
      start = parent.getAttribute('start')
      index = Array::indexOf.call(parent.children, node)
      prefix = (if start then Number(start) + index else index + 1) + '. '
    prefix + content + (if node.nextSibling and !/\n$/.test(content) then '\n' else '')


md_html_li = (md)=>
  pre = ""
  if md.startsWith("---\n")
    end = md.indexOf("\n---\n",4)
    if end > 0
      end += 5
      pre = md[..end]
      md = md[end+1..]

  html = await cmark.renderHtml(
    md
    {
      hardbreaks:true
      liberalHtmltag: true
      unsafe: true
      extensions:
        strikethrough: true
    }
  )

  html = html.replace(
    /\[([^\]]+)\]\(([^)]+)\)/g
    (_,text,link)=>
      """<a href="#{encode link}">#{text}</a>"""
  )

  pli = html.split('</p>')
  t = pli.pop()
  li = []
  for i from pli
    li.push i+'</p>'
  li.push t

  [pre, li, md]

tran = (dir, file, md, to, from_lang)=>
  [pre,li] = await md_html_li md

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
      [_pre,_li,_md] = await md_html_li read out_fp
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
        if _pre != pre
          write(out_fp,pre+_md)
        return

  console.log from_lang,'→',out_fp
  n = 0
  for await i from tranHtml(ili, to, from_lang)
    p = pli[n++]
    out[p] = i

  html = out.join('')
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
    to, turndownService.turndown(html), md
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

< translateMd = (root,dir,file,src,to)=>
  workdir = root+dir+src
  fp = workdir+'/'+file
  md = read fp

  if to == 'zh-TW' and src == 'zh'
    write(
      root+dir+to+'/'+file
      j2f md
    )
  else
    await tran root+dir,file,md,to,src

  return
