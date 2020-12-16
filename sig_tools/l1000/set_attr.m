function set_attr(h, rgb, sym, isfilled, sz)
% SET_ATTR Set line style attributes.
% set_attr(H, RGB, SYN, isfilled, sz)

for ii=1:length(h)
    set(h(ii), 'color', rgb(ii,:), 'marker', sym{ii}, 'markersize', sz);
    if (isfilled(ii))
        set(h(ii), 'markerfacecolor', rgb(ii,:));
    end
end

end