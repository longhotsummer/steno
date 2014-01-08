(function(exports) {
  exports.Steno.GithubExporter = function() {
    var self = this;

    self.exportToGithub = function(branch, filename, data, commitmsg, cb) {
      self.branch = branch;
      self.filename = filename;
      self.filedata = data;
      self.commitmsg = commitmsg;
      self.cb = cb;

      // kick everything off
      self.ensureAuth();
    };

    // 1. check for a repo, fork if missing
    // 2. check for a branch, create if missing
    // 3. push file
    // 4. create pull request

    // ensure we have an auth token and setup
    // the github client
    self.ensureAuth = function() {
      // TODO: get token
      
      self.github = new Github({
        token: 'f7bd636aee1ee9864e96d819eb2a58d73997f161',
        auth: 'oauth'
      });

      self.github.getUser().show(null, function(err, user) {
        if (user) {
          self.user = user;
          self.repo = self.github.getRepo(self.user.login, 'za-by-laws');
          self.ensureRepo();
        } else {
          self.writeFailed('Error getting user info: ' + err.error);
        }
      });
    };

    // ensure we have a repo by forking (idempotent)
    self.ensureRepo = function() {
      self.github.getRepo('longhotsummer', 'za-by-laws').fork(function(err) {
        if (!err) {
          self.waitForFork();
        } else {
          self.writeFailed('Error forking repo: ' + err.error);
        }
      });
    };

    // wait for the fork operation to complete
    self.waitForFork = function() {
      self.repo.listBranches(function(err, branches) {
        if (typeof branches === 'undefined') {
          // keep waiting
          setTimeout(self.waitForFork, 500);

        } else {
          // forked, next step
          self.ensureBranch();
        }
      });
    };

    // ensure the appropriate branch exists
    self.ensureBranch = function() {
      // does the branch exist?
      self.repo.branch(self.branch, function(err) {
        if (!err || err.error == 422) {
          // branch exists
          self.writeFile();
        } else {
          self.writeFailed('Error creating branch: ' + err.error);
        }
      });
    };

    // actually write to the file
    self.writeFile = function() {
      self.repo.write(self.branch, self.filename, self.filedata, self.commitmsg, function(err) {
        if (!err) {
          self.createPullRequest();
        } else {
          self.writeFailed('Error writing to github: ' + err);
        }
      });
    };

    // create the final pull request
    self.createPullRequest = function() {
      // TODO
      self.writeSucceeded();
    };

    self.writeSucceeded = function() {
      self.cb(true, null);
    };

    self.writeFailed = function(msg) {
      self.cb(false, msg);
    };

    // what was the url we exported to?
    self.getExportedUrl = function() {
      // https://github.com/longhotsummer/za-by-laws/blob/steno-2010-cape-town-short-name/incoming/2010-cape-town-short-name.xml
      return ['https://github.com',
              self.user.login, 'za-by-laws', 'blob',
              self.branch, self.filename].join('/');
    };
  };
})(window);
