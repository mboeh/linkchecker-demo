#!/bin/sh

time ruby link_checker_celluloid_async_bad.rb url-list 2>/dev/null >/dev/null
time ruby link_checker_celluloid_async_good.rb url-list 2>/dev/null >/dev/null
time ruby link_checker_celluloid_async_slow.rb url-list 2>/dev/null >/dev/null
time ruby link_checker_celluloid_pool.rb url-list 2>/dev/null >/dev/null
time ruby link_checker_celluloid_pool_slow.rb url-list 2>/dev/null >/dev/null
time ruby link_checker_celluloid.rb url-list 2>/dev/null >/dev/null
time ruby link_checker_spike.rb url-list 2>/dev/null >/dev/null
time ruby link_checker_spike_slow.rb url-list 2>/dev/null >/dev/null

