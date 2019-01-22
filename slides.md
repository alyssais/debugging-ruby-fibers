% You may have encountered a bug in the Ruby interpreter
% Alyssa Ross, FreeAgent

<!--
This work is licensed under the Creative Commons Attribution-ShareAlike
4.0 International License. To view a copy of this license, visit
https://creativecommons.org/licenses/by-sa/4.0/.
-->

> I'm struggling to run our website on my computer. Middleman keeps
> crashing with this error (happened 6 times in the last 30minutes). Does
> anyone know how to fix it? Thank you!
>
> >     [NOTE]
> >     You may have encountered a bug in the Ruby interpreter or extension libraries.
> >     Bug reports are welcome.
> >     For details: http://www.ruby-lang.org/bugreport.html

::: notes

Middleman is a static site generator.

It takes lots of files and produces the website, then just runs an HTTP
file server.

We discovered Ruby 2.5 was the issue (as opposed to 2.3.1).

But something strange was going on here. This crash isn't a normal
crash. Ruby only produces this message if something has gone wrong with
Ruby itself, or with a Ruby native extension written in C, not with our
code.

What was going on?

:::

Can we reproduce?
-----------------

`ab -n 1000 -c 10 http://localhost:4567`

>     [NOTE]
>     You may have encountered a bug in the Ruby interpreter or extension libraries.

::: notes

ab is ApacheBench. It produces lots of parallel requests. This command
sends 1000 total requests, 10 at a time. This reliably reproduced the
crash on Ruby 2.5 and 2.4 but not on 2.3. The parallelism was important.
It would never crash serving one request at a time.

I made a simple Middleman site. That didn't have the problem. So
something we were doing was causing the crash.

I deleted code one line at a time, until I had the crash pared down
to...

:::

---

```ruby
require "fastimage"

module AssetTagHelpers
  def image_size(url)
    FastImage.size("source/components/images/#{url}")
  end
end
```

::: notes

So what's FastImage?

:::

FastImage
---------

> FastImage finds the size or type of an image given its uri by fetching
> as little as needed

::: notes

Written entirely in Ruby, so how could it be causing a C error? I'm
skeptical.

:::

---

```ruby
require "fastimage"

Array.new(500) {
  Thread.new {
    FastImage.size("source/components/images/homepage/opengraph/empathy.png")
  }
}.each(&:join)
```

>     [NOTE]
>     You may have encountered a bug in the Ruby interpreter or extension libraries.

::: notes

Call `FastImage.size` 500 times in parallel. This reliably crashed.

Time to repeat. Start deleting bits of FastImage.

:::

---

```ruby
500.times do
  Array.new(200) { |n|
    Thread.new {
      Fiber.new {
        readable = open(__FILE__)
        Fiber.yield readable.read(1)
      }.resume
    }
  }.each(&:join)
end
```

::: notes

A Fiber is a block of code that can be paused and resumed by other
blocks of code. You may know them as coroutines or generators.

This fiber opens the file it's being run from, reads one bite, and then
yields, making `#resume` return it.

But, I discovered that opening the file and reading the byte weren't
even necessary. The fiber just had to be doing _something_. Allocating a
string was enough -- the IO just made it more likely to happen.

This is all stuff that comes with Ruby, so I knew at this point that
what I'd found was a bug in Ruby itself. Some further experimenting with
this program told us that the bug was present on macOS and Solaris, but
but not on Linux. And only in Ruby 2.4 or later.

So what had changed?

:::

---

```
git clone https://github.com/ruby/ruby
git bisect good v2_3_7
git bisect bad v2_4_0
git bisect run sh -c './configure && make && ./ruby test.rb'
```

::: notes

We tell git that 2.3.7 worked, but 2.4.0 didn't. It split that range in
the middle, tested whether that commit worked, then repeated, until it
had isolated the commit that introduced the bug.

:::

---

Revision 63498
--------------

thread_pthread.c: enable thread cache by default

```diff
diff --git a/thread_pthread.c b/thread_pthread.c
index 775c32a6a7..91d7215914 100644
--- a/thread_pthread.c
+++ b/thread_pthread.c
@@ -432,7 +432,7 @@ native_thread_destroy(rb_thread_t *th)
 }

 #ifndef USE_THREAD_CACHE
-#define USE_THREAD_CACHE 0
+#define USE_THREAD_CACHE 1
 #endif

 #if USE_THREAD_CACHE
```

::: notes

So, there's something called a "thread cache", and when they turned it
on by default, we started seeing our problem.

But, while we could turn off the thread cache, that wouldn't be the
ultimate solution.

So, rebase again, but this time always use the thread cache.

:::

---

> Revision 60440
> --------------
>
> Use rb_execution_context_t instead of rb_thread_t
> to represent execution context [Feature #14038]

::: notes

Do you know what this means? I don't.

But that's okay. We can see that this is a big refactor, and looks like
a plausible place for a bug to have been introduced. We can check that
this change is what introduces the bug by checking out 2.4, reverting
just this commit, and verifying that it doesn't crash.

We now have enough information to file a bug report!

:::

---

> Bug #15250
> ----------
>
> Getting the segfault doesn’t require nearly that many iterations or
> threads, I just made sure to do it a lot so I could reproduce it
> consistently. I’ve seen it fail with as few as 20 threads.
>
> The IO isn’t necessary either. The Fiber just needs to have some work
> to do. I got it to break once by just yielding “hello world”. The IO is
> more consistent, though.
>
> I came across this bug in the wild when using the fastimage gem in a
> few threads (from middleman), which uses a Fiber to wrap IO operations.
>
> I’ve been able to reproduce on macOS 10.13, and SmartOS 2017Q4
> (Solaris). I have not been able to reproduce on Linux.
>
> As best I can tell, the crash was introduced by r60440. It is present
> in Ruby 2.5.x when compiled with the default configuration. It is not
> present in 2.4.x. It’s also present in trunk, but only if
> USE_THREAD_CACHE is disabled. (Or at least, I can’t reproduce it with
> thread caching enabled.)

::: notes

I filed this bug report. And then I waited.

:::

---

> > Sounds like a duplicate of #14561. It should be fixed on trunk already.
>
> Yes! I can confirm that this now appears to be fixed on trunk.

::: notes

By the time they got to my bug, they'd already fixed it! Oh well.

The good news is, it's fixed. Ruby 2.6 came out on 25 December, and it
no longer has this crash.

:::

Sound interesting?
------------------

Join us in Dev Platform at FreeAgent!

- Help people with weeeeeeeeeeeird bugs
- Run a HUGE CI cluster
- Make nice tools for your nice colleagues

https://www.freeagent.com/careers/

Keep in touch
-------------

Get slides, including detailed speaker notes
:   https://github.com/alyssais/debugging-ruby-fibers

Contact me
:   alyssa.ross@freeagent.com

OpenPGP
:   `7573 56D7 79BB B888 773E`
:   `415E 736C CDF9 EF51 BD97`
