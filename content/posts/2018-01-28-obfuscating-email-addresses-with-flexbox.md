---
title:  "Obfuscating email addresses with flexbox"
date:   2018-01-28 17:45:21 +0000
---
Scammers like to trawl the internet searching for poor defenseless email addresses, ripe for the spamming. Many ways have been used to try and obfuscate emails and keep them safe like escaping every character or attaching javascript that will generate the email when needed. Here I present my solution that uses flexbox.

Flexbox allows you to change the order of items inside a containing element, we can use this to separate and reorder parts of our email address in the html but present them to the user as a legible whole. 

{% highlight html %}
div {
  display: flex;
  flex-direction: row-reverse;
  justify-content: flex-end;
}
<div>
  <span>example.com</span>
  <span>@</span>
  <span>george</span>
  <span>Email me at the following address: &nbsp;</span>
</div>
{% endhighlight %}

Here we use `flex-direction: row-reverse` to reverse the order of the elements. It will look like this: 

<div style="display: flex; flex-direction: row-reverse; justify-content: flex-end;">
<span>example.com</span>
<span>@</span>
<span>george</span>
<span>Email me at the following address:&nbsp;</span>
</div>

A scammer could probably work this out if he tried hard, all he has to do is reverse the elements to recreate the address. For a more thorough attempt we can specify the order manually.

{% highlight html %}
div {
  display: flex;
}
<div>
  <span style="order: 3">@</span>
  <span style="order: 4">example.com</span>
  <span style="order: 1">Email me at the following address:&nbsp;</span>
  <span style="order: 2">george</span>
</div>
{% endhighlight %}

Here we use `order` to specify our own order so a simple reverse cannot be used. It will look like this: 

<div style="display: flex;">
<span style="order: 3">@</span>
<span style="order: 4">example.com</span>
<span style="order: 1">Email me at the following address:&nbsp;</span>
<span style="order: 2">george</span>
</div>

Unfortunately doing any of this breaks copy/paste so your user will have to type out the address, but it is better than receiving correspondence from another Nigerian prince. 