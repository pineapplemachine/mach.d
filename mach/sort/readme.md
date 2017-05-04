# mach.sort

This package provides implementations for a variety of sorting algorithms.
Most (but not all) require that their inputs be finite, have numeric length,
and allow random-access reading and writing.

## mach.sort.heapsort

- `heapsort`: Aliases `eagerheapsort`.
- `eagerheapsort`: Typical heapsort. Remarkable for its favorable worst-case complexity.
- `lazyheapsort`: Modified heapsort. Returns a range which sorts the input lazily.

## mach.sort.insertionsort

- `insertionsort`: Aliases `linearinsertionsort`.
- `linearinsertionsort`: Typical insertion sort. Good for small inputs, bad for large ones.
- `binaryinsertionsort`: Modified insertion sort. Better for larger inputs, especially when comparison is expensive.
- `copyinsertionsort`: Modified insertion sort. Generates a sorted copy without modifying the input.

## mach.sort.mergesort

- `mergesort`: Top-down stable merge sort.

## mach.sort.selectionsort

- `selectionsort`: Aliases `eagerselectionsort`.
- `eagerselectionsort`: Typical selection sort. Inefficient, but performs relatively few writes.
- `lazyselectionsort`: Modified selection sort. Returns a range which sorts the input lazily.
- `lazycopyselectionsort`: Modified selection sort. Returns a range lazily enumerating values in sorted order; doesn't modify the input.

## mach.sort.shellsort

- `shellsort`: Similar to and probably more performant than insertion sort.
