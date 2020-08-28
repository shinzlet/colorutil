# colorutil

ColorUtil is a library that enables working with colors rapidly in Crystal.
It also acts as a wrapper around
[hsluv-crystal](https://github.com/hsluv/hsluv-crystal), whose api slightly
too verbose for my liking.

Note that this is in very early development - many features that I'd like to
add haven't been implemented yet. Better documentation is to come soon.

## Goals
- Generation of color palettes with user-defined constraints
- Various interpolation methods that look clean
- Monkey-patched extensions that allow interoperability with other libraries (crsfml, etc)

### Things that would be neat
- Compile-time color conversion?

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     colorutil:
       github: shinzlet/colorutil
   ```

2. Run `shards install`

## Usage

```crystal
require "colorutil"
```

Usage instructions are not yet written, as this is a very early stage in
development.

## Contributing

1. Fork it (<https://github.com/shinzlet/colorutil/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Seth Hinz](https://github.com/shinzlet) - creator and maintainer
