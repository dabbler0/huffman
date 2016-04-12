#!/usr/bin/env coffee

helper = require '../src/helper.coffee'
huffman = require '../src/huffman.coffee'

if process.argv.length > 2
  LENGTH = Number(process.argv[2])
else
  LENGTH = 10000

if LENGTH isnt LENGTH
  console.log 'Invalid length', process.argv[2]
  throw new ArgumentError()

string = ''

# Intended frequencies
frequencies = {}
for char in 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ .!@#$%^&*()[]{}-=_+'
  frequencies[char] = Math.random()

frequencies = helper.normalize frequencies

# Get the expected entropy
entropy = 0
for key, val of frequencies
  entropy -= (Math.log(val) / Math.log(2)) * val
console.log entropy

# Generate a string
for [0...LENGTH]
  string += helper.weightedRandom frequencies

# Compress the string
compressed = huffman.compress string

console.log 'Compressed to', compressed.length, 'expected', entropy * string.length / 8

decompressed = huffman.decompress compressed

unless decompressed is string
  console.log 'ERROR decompressing.'
else
  console.log 'Decompressed successfully.'
