# Toggling Mozc Japanese IME on Ubuntu (xkb and the Eisu_toggle Red Herring)

Recently, I've been using my Ubuntu machine more. As much as I love the MBP I use for work, some of its quirks annoy me and I've also realized I probably shouldn't be doing as much personal stuff on it as I do. One of the things I devote a lot of my time to (besides Elixir and programming) is studying Japanese. In fact, studying Japanese is what drove me to learn to code, but that is a story for another day. To get much of anywhere in the way of learning Japanese, one must master the 漢字 (kanji), the Japanese character system, including being able to type it. This is vital just to be able to do something as simple as search for a book one wants to read.

The way you go about typing Japanese into a computer is to use an IME (Input Method Editor). Contrary to what one might think, the Japanese do not use a keyboard with Japanese characters on it. Instead, they use a keyboard very similar to those used by everyone else, and use the English characters phoenetically, in conjunction with an IME, to select the words they want to use. This is a very efficient way to type, and a proficient typist can use these very quickly, because it offers suggestions as you type.

On Ubuntu, this means installing an IME. There are basically two choices, [Mozc](https://code.google.com/p/mozc/) (based on Google日本語入力 (Google Japanese Input)) or Anthy. Of the two, Mozc is vastly superior. You can read about how to install them [here](http://moritzmolch.com/1453).

Once it is all properly set up, you'll be able to turn Mozc on by pressing `SUPER` + `SPACE`. However, even with Mozc on, it will be in direct input mode. You can then go up to the icon at the top of the screen and select the 平仮名 (ひらがな - hiragana) mode, or several others. This is annoying however.

In the past, it was possible to easily configure a keyboard shortcut to swap between direct input (which just types whatever you type on the keyboard) and one of the other modes very easily. On other Operating Systems it still is. But either Ubuntu or Mozc seems to have changed some things around and it is now not so easy to do. Normally, what I like to do is just to keep Mozc on and toggle between direct input and hiragana mode, depending on whether I'm typing English or Japanese.

I said earlier that Japanese keyboards were very similar to US keyboards, and they are, but they do come with a few special keys. These keys enable a Japanese typist to toggle between the various modes of their IME with a single keypress. And Ubuntu + Mozc is already set up to work with them. What this means is that if I can find a way to make the OS think I'm pressing one of these keys (despite not having it on my US keyboard) I can do what I want.

On earlier versions of Ubuntu, one would have accomplished this via the `.xmodmap` file. However, Ubuntu has switched to a new mapping system, `xkb`, which seems to be a bit more complicated and is underdocumented. The two best sources of information I found on it last night were [here](https://help.ubuntu.com/community/Custom%20keyboard%20layout%20definitions?action=show&redirect=Howto%3A+Custom+keyboard+layout+definitions) and [here](http://www.charvolant.org/~doug/xkb/html/node5.html). However, I won't make you read all of those and will instead tell you how to accomplish our goal.

Open the file `/usr/share/X11/xkb/symbols/us` and somewhere around line 8 or 9, find any two lines which look similar to the one below, add this line:

```sh
    key <COMP> {  [   Henkan, Mode_switch  ] };
```

On my machine, this tells it to send the `Henkan` and `Mode_switch` signals when I press the menu key (the menu key is the key on the right side of the space bar which falls between `alt` and `ctrl` on my keyboard, and has an odd symbol on it with several horizontal lines. If you do not have this key, or want to use something else, you may need to do a bit more research.

Everything I read suggested that the command Mozc was looking for was `Eisu_toggle` however I wasted hours on trying to figure out why this wasn't working, before deciding to take a look in `/usr/share/X11/xkb/symbols/jp`, where I discovered the `Henkan` and `Mode_switch` signals.

Next, cd into the directory `/var/lib/xkb/` where you will find several files ending in `.xkm` (I consistently had three). Remove all of them with `rm` (possibly `sudo rm`). These files are the systems compiled record of the information contained in all the xkb config files and since you just edited one, you need to remove these to get it to re-compile the configuration. Afterwards, either restart your machine or restart X with `sudo /etc/init.d/lightdm restart`. When it comes back up, you should now be able to switch Mozc on and then toggle between English and Japanese with the press of a single key. Good Luck and 頑張ってください.
