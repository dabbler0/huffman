This is a compression script using Huffman encoding. The executable file is `src/huffman.coffee`.

Run:
```
  ./src/index.coffee myfile.txt -o compressed
```

To compress `myfile.txt` into `compressed`. To extract again:

```
  ./src/index.coffee compressed -xo myfile.txt
```

Comprehensive list of all two options the program takes:
```
  -x Extract
  -o Specify file for output (stdout otherwise)
```

It also contains a simple test:
```
  npm test 10000
  # Or run
  ./test/test.coffee 10000
```

Where the argument is the length of the file to test. It generates some random text with known probabilities, compresses it, compares the size of the compressed file with that expected by the entropy of the known probabilities, then decompresses it and makes sure no information was lost.

You can also make this into a command line command as such:

```
  # Installation
  sudo npm link

  # Usage
  huffman myfile.txt -o compressed
```
