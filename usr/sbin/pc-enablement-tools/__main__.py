#! /usr/bin/env python3

import locale
from dialog import Dialog
import logging
from argparse import ArgumentParser
import sys
import pdb




def main():
    parser = ArgumentParser(prog="pc_enablemant_tool")
#    parser.add_argument("type", type=str, choices=['view', 'message'])
#    parser.add_argument('-id', '--user_id', type=int)
    parser.add_argument('-i', '--interactive-dialog', dest="interactive_dialog")
    parser.add_argument('-f', '--log-file', dest="log_file",default="./log")
    parser.add_argument("-l", "--log", dest="logLevel", choices=['DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL'], help="Set the logging level")
    
    args = parser.parse_args()
    
    
    if args.logLevel:
        logging.basicConfig(level=logging.getLevelName(args.logLevel), filename=args.log_file)
        logging.info("log in {}".format(args.log_file))


    logging.debug("test logging.debug");


    # This is almost always a good thing to do at the beginning of your programs.
    locale.setlocale(locale.LC_ALL, '')
    
    # You may want to use 'autowidgetsize=True' here (requires pythondialog >= 3.1)
    d = Dialog(dialog="dialog")
    # Dialog.set_background_title() requires pythondialog 2.13 or later
    d.set_background_title("pc enablement tools")
    # For older versions, you can use:
    #   d.add_persistent_args(["--backtitle", "My little program"])
    
    # In pythondialog 3.x, you can compare the return code to d.OK, Dialog.OK or
    # "ok" (same object). In pythondialog 2.x, you have to use d.DIALOG_OK, which
    # is deprecated since version 3.0.0.
    if d.yesno("Are you REALLY sure you want to see this?") == d.OK:
        d.msgbox("You have been warned...")
    
        # We could put non-empty items here (not only the tag for each entry)
        code, tags = d.checklist("What sandwich toppings do you like?",
                                 choices=[("enable serial console", "",             False),
                                          ("enable modemmanager debug", "",            False)],
                                 title="Do you prefer ham or spam?",
                                 backtitle="And now, for something "
                                 "completely different...")
        if code == d.OK:
            # 'tags' now contains a list of the toppings chosen by the user
            pdb.set_trace()
            logging.info("code == d.ok, choose {}".format(tags))
            logging.info("code == d.ok, choose ???")
            pass
        else:
            logging.info("code != d.ok, choose {}".format(tags))
            logging.info("code != d.ok, choose ???")
        logging.info("++++++++")
    else:
        code, tag = d.menu("OK, then you have two options:",
                           choices=[("(1)", "Leave this fascinating example"),
                                    ("(2)", "Leave this fascinating example")])
        if code == d.OK:
            # 'tag' is now either "(1)" or "(2)"
            pass




if __name__ == "__main__":
    main()

