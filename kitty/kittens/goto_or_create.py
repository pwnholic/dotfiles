#!/usr/bin/env python3

from kittens.tui.handler import result_handler


def main(args):
    pass


@result_handler(no_ui=True)
def handle_result(args, answer, target_window_id, boss):
    tab_num = int(args[1])
    tm = boss.active_tab_manager

    if tm is None:
        return

    # Create tabs until we reach the desired number
    while len(tm.tabs) < tab_num:
        boss.new_tab()

    # Go to the tab
    boss.goto_tab(tab_num)
