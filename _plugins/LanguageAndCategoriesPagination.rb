module Jekyll
    class LanguageAndCategoriesPagination < Generator
      safe true

      def generate(site)
        #loop over all available pages
        site.pages.dup.each do |page|
          # paginate the page if marked to be paginated
          paginate(site, page) if pagination_enabled?(page)
        end
      end

      #check if the current given page is marked to be paginated
      def pagination_enabled?(page)
        # the page must be named index.html and it should contain a posts_per_page key
        page.name == 'index.html' && page.data.key?('posts_per_page')
      end

      # once the site posts are filtered by language and/or category
      # the pagination is done by creating N clones of the initial page
      def paginate(site, initialPage)
        category = initialPage.data['category']
        language = initialPage.data['language']
        per_page = initialPage.data['posts_per_page']

        if category
          # the initial page requires the posts to be filtered by a category
          filteredPosts = site.categories[category]
        else
          # no category specified, load all the posts
          filteredPosts = site.posts.docs
        end

        if language
          # the initial page requires the posts to be filtered by language
          filteredPosts = filteredPosts.select { |post| post['language']==language }
        end

        # sort by date desc (the sort is lost by filter process)
        filteredPosts = filteredPosts.sort_by { |p| p.date.to_i }.reverse

        # calculate page count and totals
        total_posts = filteredPosts.size
        pagesTotal = (total_posts.to_f / per_page.to_i).ceil

        # generate N index pages to cover all the pagination
        (1..pagesTotal).each do |currentPage|

          # get only the posts that should be included on the current page
          init = (currentPage - 1) * per_page
          offset = (init + per_page - 1) >= filteredPosts.size ? filteredPosts.size : (init + per_page - 1)
          selectedPosts = filteredPosts[init..offset]

          # generate previous link
          previous_page = currentPage != 1 ? currentPage - 1 : nil
          if previous_page
            previous_page_path = previous_page != 1 ? File.join(initialPage.dir, "/#{previous_page}") : initialPage.dir
          end

          # generate next link
          next_page = currentPage != pagesTotal ? currentPage + 1 : nil
          if next_page
            next_page_path = File.join(initialPage.dir, "/#{next_page}")
          end

          # get all available variables into an array to be shared
          paginationDetails = {
            'total_pages' => pagesTotal,
            'per_page' => per_page,
            'from' => init+1,
            'to' => offset >= total_posts ? total_posts : offset+1,
            'total_posts' => total_posts,
            'posts' => selectedPosts,
            'current_page' => currentPage,
            'previous_page' => previous_page,
            'previous_page_path' => previous_page_path,
            'next_page' => next_page,
            'next_page_path' => next_page_path
          }

          # the initial page is already known by Jekyll, we only need
          # to inject the pagination details containing the filtered posts
          if currentPage <= 1
            initialPage.data['pagination'] = paginationDetails;
          else
            # all following pages (2, 3, ..N) does not exist and must be generated

            # set the target to be the dir of the initial page plus the number of the new page
            targetDir = File.join(initialPage.dir, "/#{currentPage}")

            # clone the initial page into the target dir
            newpage = ClonedPage.new(site, initialPage, targetDir)

            # inject the pagination details (containing the filtered posts) into the cloned page
            newpage.data['pagination'] = paginationDetails;

            # flag to know this is an added page (useful for dynamic menus)
            newpage.data['clonedFrom'] = initialPage.url; # so the original one can be highlighted

            # let Jekyll know about the new page
            site.pages << newpage
          end

        end
      end
    end

    # clone a given page into a target directory
    class ClonedPage < Page
      def initialize(site, basePage, targetDir)
        @site = site
        @base = site.source
        @dir = targetDir
        @name = basePage.name

        self.process(@name)
        self.read_yaml(File.join(site.source, basePage.dir), basePage.name)
      end
    end

end
