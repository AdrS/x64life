# x86_64 Game of Life
Conway's game of life written in x86_64 assembly without using glibc. 

```
$ as gameoflife.s -o gameoflife.o && ld gameoflife.o -o gameoflife
$ ./gameoflife 5 42 100
Generation

   A A
 AA
 A  A
 A AA
  AA A

Generation

  A
 AAAA
 A  A
 A   A
  AA

Generation

 AA
 A  A
 A  AA
 A AA
  A
  
 ...

Generation


   A
  A A
  A A
   A
```
