#!/usr/bin/env coffee

> ./j2f.js
  ./tran.js > tranHtml
  cmark-gfm:cmark
  @u7/read
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


tran = (md)=>
  pre = ""
  if md.startsWith("---\n")
    end = md.indexOf("\n---\n",4)
    if end > 0
      end += 5
      pre = md[..end]
      md = md[end+1..]

  html = await cmark.renderHtml md,{
    hardbreaks:true
    extensions:
      strikethrough: true
  }
  #html = await deepl.xml(html, target_lang)
  txt = turndownService.turndown html

  # 翻译注释，先不搞，以后再说
  #txt = await translate_comment(
  #  txt
  #  (t)=>
  #    if deepl.source_lang == "ZH"
  #      if /^[\x00-\x7F]*$/.test(t)
  #        return t
  #    deepl.txt(t,target_lang)

  #)
  pre+txt

< translateMd = (root,dir,file,src,to)=>
  fp = root+dir+src+'/'+file
  md = read fp
  #console.log await tran md
  return
