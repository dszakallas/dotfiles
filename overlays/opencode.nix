_: fix: prev: {
  opencode = prev.opencode.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace packages/core/src/filesystem/search.ts \
        --replace-fail 'import { FileSystem } from "../filesystem"' 'import { Entry, Match } from "@opencode-ai/schema/filesystem"; import type { FileSystem } from "../filesystem"' \
        --replace-fail 'FileSystem.Entry.make' 'Entry.make' \
        --replace-fail 'FileSystem.Match.make' 'Match.make'
    '';
  });
}
