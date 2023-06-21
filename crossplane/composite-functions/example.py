import sys

import requests
import yaml

ANNOTATION_KEY_AUTHOR = "quotable.io/author"
ANNOTATION_KEY_QUOTE = "quotable.io/quote"


def get_quote() -> tuple[str, str]:
    """Get a quote from quotable.io"""
    rsp = requests.get("https://api.quotable.io/random")
    rsp.raise_for_status()
    j = rsp.json()
    return (j["author"], j["content"])


def read_Functionio() -> dict:
    """Read the FunctionIO from stdin."""
    return yaml.load(sys.stdin.read(), yaml.Loader)


def write_Functionio(Functionio: dict):
    """Write the FunctionIO to stdout and exit."""
    sys.stdout.write(yaml.dump(Functionio))
    sys.exit(0)


def result_warning(Functionio: dict, message: str):
    """Add a warning result to the supplied FunctionIO."""
    if "results" not in Functionio:
        Functionio["results"] = []
    Functionio["results"].append({"severity": "Warning", "message": message})


def main():
    """Annotate all desired composed resources with a quote from quotable.io"""
    try:
        Functionio = read_Functionio()
    except yaml.parser.ParserError as err:
        sys.stdout.write("cannot parse FunctionIO: {}\n".format(err))
        sys.exit(1)

    # Return early if there are no desired resources to annotate.
    if "desired" not in Functionio or "resources" not in Functionio["desired"]:
        write_Functionio(Functionio)

    # If we can't get our quote, add a warning and return early.
    try:
        quote, author = get_quote()
    except requests.exceptions.RequestException as err:
        result_warning(Functionio, "Cannot get quote: {}".format(err))
        write_Functionio(Functionio)

    # Annotate all desired resources with our quote.
    for r in Functionio["desired"]["resources"]:
        if "resource" not in r:
            # This shouldn't happen - add a warning and continue.
            result_warning(
                Functionio,
                "Desired resource {name} missing resource body".format(
                    name=r.get("name", "unknown")
                ),
            )
            continue

        if "metadata" not in r["resource"]:
            r["resource"]["metadata"] = {}

        if "annotations" not in r["resource"]["metadata"]:
            r["resource"]["metadata"]["annotations"] = {}

        if ANNOTATION_KEY_QUOTE in r["resource"]["metadata"]["annotations"]:
            continue

        r["resource"]["metadata"]["annotations"][ANNOTATION_KEY_AUTHOR] = author
        r["resource"]["metadata"]["annotations"][ANNOTATION_KEY_QUOTE] = quote

    write_Functionio(Functionio)


if __name__ == "__main__":
    main()