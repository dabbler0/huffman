#!/usr/bin/env coffee

helper = require './helper.coffee'
huffman = require './huffman.coffee'
minimist = require 'minimist'
fs = require 'fs'

argv = minimist process.argv.slice 2

original = fs.readFileSync(argv._[0]).toString()
if argv.x
  result = huffman.decompress original
  console.log "Extracted #{original.length} bytes from #{result.length} (factor of #{original.length/result.length})."
else
  result = huffman.compress fs.readFileSync(argv._[0]).toString()
  console.log "Compressed #{original.length} bytes to #{result.length} (factor of #{original.length/result.length})."

if argv.o
  fs.writeFileSync argv.o, result
else
  console.log result
