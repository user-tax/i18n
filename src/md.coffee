#!/usr/bin/env coffee

> ./j2f.js
  ./LANG_LI.js
  ./tran.js > tranHtml

< translateMd = (root,dir,file,src,to)=>
  console.log {
    root,dir,file,src,to
  }
  return

