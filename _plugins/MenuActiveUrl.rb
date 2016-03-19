# Selects the closest url that could be the parent of each page/post
# Only pages can be parent of other pages or posts
module Jekyll
    class MenuActiveUrl < Generator
      safe true

      def generate(site)
        #loop over all available pages
        site.pages.dup.each do |page|
          selectActiveMenuURL(site, page)
        end
        #loop over all available posts
        site.posts.docs.dup.each do |post|
          selectActiveMenuURL(site, post)
        end
      end

      # for a given page, choose an url to be active on the menu
      def selectActiveMenuURL(site, currentPage)
        availablePages = site.pages

        activeUrl = nil
        currentUrl = currentPage.url
        while activeUrl == nil do

            # check if the current url matchs against
            # any page that will be included on the menu
            for menuItem in availablePages
              url = menuItem.url
              if currentUrl == url or currentUrl == url.chomp("/")
                activeUrl = url
                break
              end
            end

            # if not, make a shorter version and try again
            currentUrl = currentUrl.rpartition('/').first
            if currentUrl == ""
              # unable to mark this one on the menu
              break
            end
        end

        # set the active url to be activated on the menu
        currentPage.data['activeUrl'] = activeUrl
      end

    end
end
