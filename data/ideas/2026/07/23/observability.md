sidecars must be forget.able but for things like status polling / health / heartbeats, any lock TTL must be reset (expire.able ? daemons / crontabs are usable for this)

--

logging helpers : "repeat.when" for conditional stdout logging ?

--

Important software wrappers for auto log levels uniformize.able ?

--

**Shortcut**  
**Target**  
lt  
logged-thread  
lc  
logged-chain  
lb  
logged-batch  
lp  
logged-pipe  
ll  
logged-loop

The addition of new implementations should be done in sync with their own "ideal" representation as cwt presets.

Update the plan to include that in its scope.

--

Now, does it make sense to have the default cwt core to have out-of-the-box something implementing its own hooks (like gpu and log storage) serving as an overridable default for debian hosts that :

- by default, monitor all host-level threads (opt-in behaviour from the thread subject) via crontab (overridable default, must be easily switched via a dedicated prefixed env var) so that any CWT instance (nested or not) can know about their respective siblings (if they're running already, etc).  
- offer instance-level loop monitoring (what is running, is stale, finished...)

that default cwt observability / monitoring needs a global off switch.

The plan also needs to include new living documentation files to be created at docs/[observability.md](http://observability.md) and docs/[monitoring.md](http://monitoring.md)

--

slot.able = eval.able filled by heredoc.able ?

-s  
Changeli.reviwabv

TODO aberration.catcher : daemon worker pour détecter genre telle owner a plus de 100 threads, plus de 50% de onso mémoire totale, etc.

crash prevention ?

--

tailed remote file sync :  
data/remote-$entity (data/remote-instance, data/remote-host, data/remote-aws, data/remote-s3 etc.) tailed logs didecars ex :

data/remote-instance/ = REMOTE\_INSTANCE\_DOCROOT

data/remote-instance/$data\_subdir/*.tailsync.txt ?

make tail = loop-wrap   
make logged-tail = log-wrap loop-wrap (debounced ?)

remote-tail, remote-logged-tail ?

--

Offloading more ?

Limits (snacks css) - scope - context  
Yml hooks everywhere (context, suitable next steps...)
